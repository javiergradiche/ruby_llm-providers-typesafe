# frozen_string_literal: true

module RubyLLM
  module Providers
    class Typesafe < Provider
      class SystemOne < Protocol
        # Model listing for the System One API. Every model is billed per
        # input token; output tokens are free.
        module Models
          INPUT_PRICE_PER_MILLION = 0.042

          def models_url
            'v1/models'
          end

          def parse_list_models_response(response, slug)
            Array(response.body['models']).map do |model_data|
              Model.new(
                id: model_data['name'],
                name: model_data['name'],
                provider: slug,
                created_at: model_data['release_date'],
                modalities: { input: ['text'], output: ['rerank'] },
                capabilities: [],
                pricing: { text_tokens: { standard: { input_per_million: INPUT_PRICE_PER_MILLION,
                                                      output_per_million: 0 } } },
                metadata: { description: model_data['description'] }.compact
              )
            end
          end
        end
      end
    end
  end
end
