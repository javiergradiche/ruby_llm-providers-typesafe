# frozen_string_literal: true

RSpec.shared_context 'with configured RubyLLM' do
  before do
    RubyLLM.configure do |config|
      config.typesafe_api_key = ENV.fetch('TYPESAFE_API_KEY', 'test')
      config.typesafe_api_base = ENV.fetch('TYPESAFE_API_BASE', 'https://api.typesafe.ai')
      config.max_retries = 0
      config.retry_backoff_factor = 0
      config.retry_interval = 0
      config.retry_interval_randomness = 0
    end
  end
end
