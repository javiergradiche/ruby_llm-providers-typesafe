# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Rerank do
  include_context 'with configured RubyLLM'

  around do |example|
    VCR.turned_off { example.run }
  end

  before do
    stub_request(:post, 'https://api.typesafe.ai/v1/systemone').to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: { model: 'jev-1.13.0',
              answers: { 'document_0' => { type: 'noul', noul: 0.2 }, 'document_1' => { type: 'noul', noul: 0.9 } },
              usage: { input_tokens: 100, output_tokens: 4 } }.to_json
    )
  end

  it 'ranks documents and records usage' do
    rerank = RubyLLM.rerank('Capital of the US?', ['Carson City is in Nevada.', 'Washington, D.C.'],
                            model: 'jev-latest', provider: :typesafe)

    expect(rerank.results.map(&:document)).to eq(['Washington, D.C.', 'Carson City is in Nevada.'])
    expect(rerank.tokens.input).to eq(100)
  end

  it 'raises a RubyLLM error for an invalid API key' do
    stub_request(:post, 'https://api.typesafe.ai/v1/systemone')
      .to_return(status: 401, headers: { 'Content-Type' => 'application/json' },
                 body: { detail: 'Invalid API key' }.to_json)

    expect { RubyLLM.rerank('q', %w[a b], model: 'jev-latest', provider: :typesafe) }
      .to raise_error(RubyLLM::UnauthorizedError, 'Invalid API key')
  end
end
