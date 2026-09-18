# frozen_string_literal: true

source 'lib/**/*.rb'

component :provider,
          in: %w[
            lib/ruby_llm/providers/typesafe.rb
            lib/ruby_llm/providers/typesafe/**/*.rb
          ],
          namespace: 'RubyLLM::Providers::Typesafe'

provider.cannot_reference_constants 'RSpec', 'WebMock', 'VCR'

preset :ruby_conventions

component :api,
          in: %w[
            lib/ruby_llm/typesafe.rb
            lib/ruby_llm/typesafe/**/*.rb
          ],
          namespace: 'RubyLLM::Typesafe'

api.cannot_reference_constants 'RubyLLM::Providers', 'RSpec', 'WebMock', 'VCR'
