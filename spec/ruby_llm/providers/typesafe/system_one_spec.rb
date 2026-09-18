# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::Typesafe::SystemOne do
  subject(:protocol) { described_class.new(provider, model) }

  let(:config) do
    RubyLLM::Configuration.new.tap { |provider_config| provider_config.typesafe_api_key = 'test-key' }
  end
  let(:provider) { RubyLLM::Providers::Typesafe.new(config) }
  let(:model) do
    RubyLLM::Model.new(id: 'jev-latest', provider: 'typesafe',
                       pricing: { text_tokens: { standard: { input_per_million: 0.042, output_per_million: 0 } } })
  end
  let(:response) { Struct.new(:body) }

  def questions(&)
    RubyLLM::Typesafe::Questions.new.tap(&)
  end

  describe '#render_evaluation_payload' do
    it 'renders each question type in the wire vocabulary' do
      payload = protocol.render_evaluation_payload(
        { ticket: 'Payouts failing' },
        questions do |q|
          q.noul :urgent, 'Does this convey urgency?', yes: 'Time-sensitive', no: 'Not urgent'
          q.choice :team, 'Which team?', billing: 'Payments', technical: nil
          q.score :frustration, 'How frustrated?', %w[Calm Angry]
        end,
        model: 'jev-latest'
      )

      expect(payload).to eq(
        state: { ticket: 'Payouts failing' },
        model: 'jev-latest',
        questions: {
          'urgent' => { type: 'noul', instructions: 'Does this convey urgency?',
                        criteria: { true => 'Time-sensitive', false => 'Not urgent' } },
          'team' => { type: 'choice', instructions: 'Which team?',
                      criteria: { 'billing' => 'Payments', 'technical' => nil } },
          'frustration' => { type: 'score', instructions: 'How frustrated?', criteria: %w[Calm Angry] }
        }
      )
    end

    it 'omits noul criteria when neither answer is described' do
      payload = protocol.render_evaluation_payload('text', questions { |q| q.noul :spam, 'Is this spam?' },
                                                   model: 'jev-latest')

      expect(payload[:questions]['spam']).to eq(type: 'noul', instructions: 'Is this spam?')
    end
  end

  describe '#parse_evaluation_response' do
    let(:asked) do
      questions do |q|
        q.noul :urgent, 'Does this convey urgency?'
        q.choice :team, 'Which team?', %i[billing technical]
        q.score :frustration, 'How frustrated?', ['Calm', 'Frustrated', 'Very angry']
      end
    end
    let(:body) do
      {
        'model' => 'jev-1.13.0',
        'answers' => {
          'urgent' => { 'type' => 'noul', 'noul' => 0.92 },
          'team' => { 'type' => 'choice', 'choice' => 'technical',
                      'probabilities' => { 'billing' => 0.15, 'technical' => 0.85 }, 'confidence' => 0.82 },
          'frustration' => { 'type' => 'score', 'score' => 1.6,
                             'legend' => { '0' => 'Calm', '1' => 'Frustrated', '2' => 'Very angry' },
                             'probabilities' => { '0' => 0.05, '1' => 0.3, '2' => 0.65 }, 'confidence' => 0.78 }
        },
        'usage' => { 'input_tokens' => 312, 'output_tokens' => 48 }
      }
    end
    let(:evaluation) { protocol.parse_evaluation_response(response.new(body), asked) }

    it 'reads a noul answer as a probability' do
      expect(evaluation[:urgent].probability).to eq(0.92)
      expect(evaluation[:urgent]).to be_yes
      expect(evaluation[:urgent].yes?(threshold: 0.95)).to be(false)
    end

    it 'maps a choice answer back to the option keys that were asked' do
      expect(evaluation[:team].option).to eq(:technical)
      expect(evaluation[:team].probabilities).to eq(billing: 0.15, technical: 0.85)
      expect(evaluation[:team].confidence).to eq(0.82)
    end

    it 'orders score probabilities by level' do
      expect(evaluation[:frustration].score).to eq(1.6)
      expect(evaluation[:frustration].probabilities).to eq([0.05, 0.3, 0.65])
      expect(evaluation[:frustration].level).to eq('Very angry')
    end

    it 'reports the answering model, tokens, and input-only cost' do
      expect(evaluation.model).to eq('jev-1.13.0')
      expect(evaluation.tokens.input).to eq(312)
      expect(evaluation.tokens.output).to eq(48)
      expect(evaluation.cost.total).to be_within(1e-12).of(312 * 0.042 / 1_000_000)
    end
  end

  describe 'reranking' do
    let(:documents) { ['Carson City is the capital of Nevada.', 'Washington, D.C. is the capital of the US.'] }
    let(:body) do
      {
        'model' => 'jev-1.13.0',
        'answers' => { 'document_0' => { 'type' => 'noul', 'noul' => 0.1 },
                       'document_1' => { 'type' => 'noul', 'noul' => 0.95 } },
        'usage' => { 'input_tokens' => 120, 'output_tokens' => 4 }
      }
    end

    it 'asks one relevance question per document over a shared state' do
      payload = protocol.render_rerank_payload('Capital of the US?', documents, model: 'jev-latest')

      expect(payload[:state]).to eq(query: 'Capital of the US?', documents: documents)
      expect(payload[:questions].keys).to eq(%w[document_0 document_1])
      expect(payload[:questions]['document_1']).to include(type: 'noul',
                                                           instructions: 'Does `documents[1]` help answer `query`?')
    end

    it 'merges provider options into the payload' do
      payload = protocol.render_rerank_payload('q', documents, model: 'jev-latest',
                                                               provider_options: { model: 'jev-preview' })

      expect(payload[:model]).to eq('jev-preview')
    end

    it 'sorts documents by the probability that they are relevant' do
      protocol.render_rerank_payload('Capital of the US?', documents, model: 'jev-latest')
      rerank = protocol.parse_rerank_response(response.new(body), model: 'jev-latest', documents: documents)

      expect(rerank.results.map(&:index)).to eq([1, 0])
      expect(rerank.results.first.score).to eq(0.95)
      expect(rerank.results.first.document).to eq(documents[1])
      expect(rerank.model).to eq('jev-1.13.0')
      expect(rerank.tokens.input).to eq(120)
    end

    it 'keeps only the top_n results' do
      protocol.render_rerank_payload('Capital of the US?', documents, model: 'jev-latest', top_n: 1)
      rerank = protocol.parse_rerank_response(response.new(body), model: 'jev-latest', documents: documents)

      expect(rerank.results.map(&:index)).to eq([1])
    end
  end

  describe '#parse_list_models_response' do
    it 'builds rerank models priced per input token' do
      body = { 'models' => [{ 'name' => 'jev-latest', 'description' => 'Flagship', 'release_date' => '2026-06-01' }] }
      models = protocol.parse_list_models_response(response.new(body), 'typesafe')

      expect(models.map(&:id)).to eq(['jev-latest'])
      expect(models.first.type).to eq(:rerank)
      expect(models.first.pricing.text_tokens.input).to eq(0.042)
      expect(models.first.metadata).to eq(description: 'Flagship')
    end
  end
end
