# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'ruby_llm-providers-typesafe'
  spec.version = '0.1.0'
  spec.authors = ['Javier Gradiche']
  spec.email = ['javiergradiche@gmail.com']

  spec.summary = 'TypeSafe System One models, such as Jev, for RubyLLM.'
  spec.description = 'Typed judgments and reranking with the TypeSafe Jev model through RubyLLM.'
  spec.homepage = 'https://github.com/javiergradiche/ruby_llm-providers-typesafe'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/releases"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob('{lib,spec}/**/*') +
               Dir.glob('.github/workflows/*.yml') +
               Dir.glob('models.json') +
               %w[.flayignore .overcommit.yml .rspec .rubocop.yml Archspec.rb LICENSE README.md]
  spec.require_paths = ['lib']

  spec.add_dependency 'ruby_llm', '>= 2.0.0.rc1'
end
