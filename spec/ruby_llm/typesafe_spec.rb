# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Typesafe do
  include_context 'with configured RubyLLM'

  describe '.evaluate' do
    before do
      stub_request(:post, 'https://api.typesafe.ai/v1/systemone')
        .with(body: hash_including('model' => 'jev-latest', 'state' => 'Help! My payouts have been failing.'))
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { model: 'jev-1.13.0', answers: { urgent: { type: 'noul', noul: 0.9 } },
                  usage: { input_tokens: 20, output_tokens: 2 } }.to_json
        )
    end

    around do |example|
      VCR.turned_off { example.run }
    end

    it 'returns an Evaluation keyed by question id' do
      evaluation = described_class.evaluate('Help! My payouts have been failing.') do |q|
        q.noul :urgent, 'Does this convey urgency?'
      end

      expect(evaluation).to be_a(RubyLLM::Typesafe::Evaluation)
      expect(evaluation[:urgent].probability).to eq(0.9)
      expect(evaluation.model).to eq('jev-1.13.0')
    end

    it 'requires a block' do
      expect { described_class.evaluate('text') }.to raise_error(ArgumentError, /requires a block/)
    end

    it 'requires at least one question' do
      expect { described_class.evaluate('text') { nil } }.to raise_error(ArgumentError, /at least one question/)
    end
  end

  describe 'questions' do
    subject(:questions) { RubyLLM::Typesafe::Questions.new }

    it 'rejects a duplicate id' do
      questions.noul :spam, 'Is this spam?'

      expect { questions.noul :spam, 'Is this spam?' }.to raise_error(ArgumentError, /already defined/)
    end

    it 'requires two options for a choice' do
      expect { questions.choice :team, 'Which team?', billing: 'Payments' }.to raise_error(ArgumentError)
    end

    it 'requires two levels for a score' do
      expect { questions.score :tone, 'How warm?', ['Cold'] }.to raise_error(ArgumentError)
    end
  end
end
