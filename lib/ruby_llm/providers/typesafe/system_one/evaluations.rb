# frozen_string_literal: true

module RubyLLM
  module Providers
    class Typesafe < Provider
      class SystemOne < Protocol
        # Renders Typesafe::Questions to the wire and parses the answers
        # into a Typesafe::Evaluation.
        module Evaluations
          def evaluation_url
            'v1/systemone'
          end

          def evaluate(state, questions, model:)
            response = @connection.post evaluation_url, render_evaluation_payload(state, questions, model:)
            parse_evaluation_response(response, questions)
          end

          def render_evaluation_payload(state, questions, model:)
            {
              state: state,
              model: model,
              questions: questions.to_h.to_h { |id, question| [id.to_s, render_question(question)] }
            }
          end

          def render_question(question)
            rendered = { type: question.type.to_s, instructions: question.instructions }
            criteria = render_criteria(question)
            criteria ? rendered.merge(criteria: criteria) : rendered
          end

          def parse_evaluation_response(response, questions)
            data = response.body
            answers = questions.to_h.to_h do |id, question|
              [id, parse_answer(question, data.dig('answers', id.to_s) || {})]
            end
            usage = data['usage'] || {}

            RubyLLM::Typesafe::Evaluation.new(
              answers: answers,
              model: data['model'],
              tokens: Tokens.new(input: usage['input_tokens'], output: usage['output_tokens']),
              model_info: @model,
              raw: data
            )
          end

          def parse_answer(question, data)
            case question.type
            when :noul then RubyLLM::Typesafe::Evaluation::Noul.new(probability: data['noul'])
            when :choice then parse_choice_answer(question, data)
            when :score then parse_score_answer(question, data)
            end
          end

          private

          def render_criteria(question)
            case question.type
            when :noul
              criteria = { true => question.criteria[:yes], false => question.criteria[:no] }.compact
              criteria unless criteria.empty?
            when :choice then question.criteria.to_h { |option, description| [option.to_s, description] }
            when :score then question.criteria
            end
          end

          def parse_choice_answer(question, data)
            options = question.criteria.keys.to_h { |option| [option.to_s, option] }

            RubyLLM::Typesafe::Evaluation::Choice.new(
              option: options.fetch(data['choice'], data['choice']),
              probabilities: (data['probabilities'] || {}).to_h do |option, value|
                [options.fetch(option, option), value]
              end,
              confidence: data['confidence']
            )
          end

          def parse_score_answer(question, data)
            levels = question.criteria

            RubyLLM::Typesafe::Evaluation::Score.new(
              score: data['score'],
              levels: levels,
              probabilities: levels.each_index.map { |index| data.dig('probabilities', index.to_s) },
              confidence: data['confidence']
            )
          end
        end
      end
    end
  end
end
