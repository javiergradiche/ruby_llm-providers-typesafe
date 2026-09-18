# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Providers::Typesafe do
  subject(:provider) { described_class.new(config) }

  let(:config) do
    RubyLLM::Configuration.new.tap do |provider_config|
      provider_config.typesafe_api_key = 'test-key'
      provider_config.typesafe_api_base = 'https://example.test'
    end
  end

  it 'is registered with RubyLLM' do
    expect(RubyLLM::Provider.resolve(:typesafe)).to eq(described_class)
  end

  it 'speaks the System One protocol' do
    expect(described_class.protocols).to eq(system_one: described_class::SystemOne)
  end

  it 'declares provider configuration' do
    expect(described_class.configuration_options).to eq(%i[typesafe_api_key typesafe_api_base])
    expect(described_class.configuration_requirements).to eq(%i[typesafe_api_key])
  end

  it 'uses configured API base and bearer token' do
    expect(provider.api_base).to eq('https://example.test')
    expect(provider.headers).to eq('Authorization' => 'Bearer test-key')
  end

  it 'defaults to the public API base' do
    config.typesafe_api_base = nil

    expect(provider.api_base).to eq('https://api.typesafe.ai')
  end

  it 'reads the message from an error detail' do
    response = Struct.new(:body).new(
      { 'detail' => { 'error_type' => 'authentication_error', 'message' => 'Cannot authenticate with the server.' } }
    )

    expect(provider.parse_error(response)).to eq('Cannot authenticate with the server.')
  end

  it 'joins validation details into the error message' do
    response = Struct.new(:body).new({ 'detail' => [{ 'msg' => 'Field required' }, { 'msg' => 'Too short' }] })

    expect(provider.parse_error(response)).to eq('Field required. Too short')
  end

  it 'falls back to the standard error message' do
    response = Struct.new(:body).new({ 'error' => { 'message' => 'Invalid API key' } })

    expect(provider.parse_error(response)).to eq('Invalid API key')
  end
end
