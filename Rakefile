# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

desc 'Refresh the Typesafe model catalog'
task :models do
  require 'dotenv/load'
  require_relative 'lib/ruby_llm/providers/typesafe'

  RubyLLM.configure do |config|
    config.typesafe_api_key = ENV.fetch('TYPESAFE_API_KEY', nil)
    config.typesafe_api_base = ENV.fetch('TYPESAFE_API_BASE', 'https://api.typesafe.ai')
  end

  provider = RubyLLM::Provider.resolve!(:typesafe).new(RubyLLM.config)
  models = provider.list_models
  abort 'Typesafe returned no models' if models.empty?

  RubyLLM::Models.new(models).save_to_json(File.expand_path('models.json', __dir__))
end

desc 'Run Flay duplicate detection'
task :flay do
  sh 'bundle exec flay --mass 70 lib spec'
end

desc 'Run ArchSpec architecture checks'
task :archspec do
  sh 'bundle exec archspec check'
end

task default: %i[rubocop flay archspec spec]
