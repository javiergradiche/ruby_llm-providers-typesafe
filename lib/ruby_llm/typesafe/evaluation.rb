# frozen_string_literal: true

module RubyLLM
  module Typesafe
    # The answers to one Typesafe.evaluate call, keyed by the ids you gave
    # the questions.
    #
    #   evaluation[:urgent].probability # => 0.92
    #   evaluation.cost.total           # => 0.0000131
    #
    class Evaluation
      include Support::Inspectable

      # The answer to a yes/no question. +probability+ is the chance the
      # answer is yes, from 0 to 1.
      Noul = Struct.new(:probability, keyword_init: true) do
        # Returns whether +probability+ reaches +threshold+. Tune the
        # threshold on your own data and consequences.
        def yes?(threshold: 0.5)
          probability >= threshold
        end
      end

      # The answer to a choice question. +option+ is the most probable
      # option, +probabilities+ maps every option to its probability, and
      # +confidence+ (0 to 1) says how concentrated they are.
      Choice = Struct.new(:option, :probabilities, :confidence, keyword_init: true)

      # The answer to a score question. +score+ is the probability-weighted
      # level index and can land between levels. +probabilities+ holds one
      # probability per level, in the order of +levels+.
      Score = Struct.new(:score, :levels, :probabilities, :confidence, keyword_init: true) do
        # Returns the level description nearest to +score+.
        def level
          levels[score.round]
        end
      end

      # The answers as a Hash of question id to Noul, Choice, or Score.
      attr_reader :answers

      # The versioned id of the model that answered, such as "jev-1.13.0".
      attr_reader :model

      # The raw provider response body.
      attr_reader :raw

      # The Tokens the evaluation used.
      attr_reader :tokens

      def initialize(answers:, model:, tokens:, model_info: nil, raw: nil) # :nodoc:
        @answers = answers
        @model = model
        @tokens = tokens
        @model_info = model_info
        @raw = raw
      end

      # Returns the answer to the question with +id+.
      def [](id)
        answers.fetch(id)
      end

      # Returns the evaluation's Cost, or a Cost with a +nil+ total when the
      # model has no known pricing.
      def cost
        Cost.new(tokens: tokens, model: @model_info)
      end

      def inspect_attributes # :nodoc:
        { model: model, answers: answers.keys }
      end
    end
  end
end
