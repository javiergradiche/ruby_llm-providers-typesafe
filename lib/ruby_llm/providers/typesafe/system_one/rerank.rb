# frozen_string_literal: true

module RubyLLM
  module Providers
    class Typesafe < Provider
      class SystemOne < Protocol
        # Reranking as one request: the query and documents form the state,
        # and each document gets its own relevance question. The noul, the
        # probability that the document is relevant, is its score.
        module Rerank
          RELEVANCE_CRITERIA = {
            true => 'The document contains information that answers or directly addresses the query.',
            false => 'The document is off topic or only shares words with the query.'
          }.freeze

          def rerank_url
            evaluation_url
          end

          def render_rerank_payload(query, documents, model:, top_n: nil, provider_options: {})
            @top_n = top_n
            questions = documents.each_index.to_h do |index|
              [rerank_question_id(index), { type: 'noul', instructions: relevance_instructions(index),
                                            criteria: RELEVANCE_CRITERIA }]
            end

            { state: { query: query, documents: documents }, model: model, questions: questions }
              .merge(provider_options)
          end

          def parse_rerank_response(response, model:, documents: [])
            data = response.body
            results = documents.each_with_index.map do |document, index|
              RubyLLM::Rerank::Result.new(index: index, document: document,
                                          score: data.dig('answers', rerank_question_id(index), 'noul'))
            end
            results = results.sort_by { |result| -result.score.to_f }
            results = results.first(@top_n) if @top_n

            RubyLLM::Rerank.new(results: results, model: data['model'] || model, raw: data,
                                input_tokens: data.dig('usage', 'input_tokens'))
          end

          private

          def rerank_question_id(index)
            "document_#{index}"
          end

          def relevance_instructions(index)
            "Does `documents[#{index}]` help answer `query`?"
          end
        end
      end
    end
  end
end
