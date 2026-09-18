# frozen_string_literal: true

require 'ruby_llm'
require_relative '../typesafe'
require_relative 'typesafe/system_one'

module RubyLLM
  module Providers
    # TypeSafe API integration. TypeSafe's System One models, such as Jev,
    # answer typed questions about a state instead of generating text.
    class Typesafe < Provider
      protocol :system_one, SystemOne

      def api_base
        @config.typesafe_api_base || 'https://api.typesafe.ai'
      end

      def headers
        { 'Authorization' => "Bearer #{@config.typesafe_api_key}" }
      end

      def evaluate(state, questions, model:) # :nodoc:
        resolve_protocol(nil, model).new(self, model).evaluate(state, questions, model: model_id_for(model))
      end

      def parse_error(response) # :nodoc:
        body = parse_error_body(response)
        detail = body['detail'] if body.is_a?(Hash)

        case detail
        when Hash then detail['message'] || super
        when Array then detail.map { |part| detail_message(part) }.join('. ')
        when String then detail
        else super
        end
      end

      class << self
        def display_name
          'TypeSafe'
        end

        def configuration_options
          %i[typesafe_api_key typesafe_api_base]
        end

        def configuration_requirements
          %i[typesafe_api_key]
        end

        # The model listing returns aliases only, while versioned ids such
        # as jev-1.13.0 are accepted too.
        def assume_models_exist?
          true
        end
      end

      private

      def detail_message(part)
        part.is_a?(Hash) ? part['msg'].to_s : part.to_s
      end
    end
  end
end

RubyLLM::Provider.register :typesafe, RubyLLM::Providers::Typesafe,
                           models: File.expand_path('../../../models.json', __dir__)
