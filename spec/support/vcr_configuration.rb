# frozen_string_literal: true

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.default_cassette_options = { record: ENV['CI'] ? :none : :once }
  config.allow_http_connections_when_no_cassette = true
  config.filter_sensitive_data('<TYPESAFE_API_KEY>') { ENV.fetch('TYPESAFE_API_KEY', nil) }
  config.filter_sensitive_data('<TYPESAFE_API_BASE>') { ENV.fetch('TYPESAFE_API_BASE', nil) }

  config.before_record do |interaction|
    next unless interaction.request.headers['Authorization']

    interaction.request.headers['Authorization'] = ['Bearer <AUTH_TOKEN>']
  end
end
