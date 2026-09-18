# frozen_string_literal: true

module RubyLLM
  module Typesafe
    # Collects the questions for one evaluation. Typesafe.evaluate yields
    # one to its block. Each question gets an id you choose; its answer
    # comes back under the same id. Ids are for your code and never reach
    # the model, so the instructions must carry the full meaning.
    class Questions
      # One question: its +type+ (:noul, :choice, or :score), its
      # +instructions+, and its +criteria+.
      Question = Struct.new(:type, :instructions, :criteria, keyword_init: true)

      def initialize # :nodoc:
        @questions = {}
      end

      # Adds a yes/no question. Its answer is the probability that the
      # answer is yes. +yes:+ and +no:+ optionally describe what each
      # answer means.
      #
      #   q.noul :urgent, "Does this convey urgency?", yes: "Explicitly time-sensitive"
      #
      def noul(id, instructions, yes: nil, no: nil)
        add id, Question.new(type: :noul, instructions: instructions, criteria: { yes: yes, no: no })
      end

      # Adds a question that picks one of +options+. Pass a Hash of option
      # to description, or an Array of options that need no description.
      # The answer names the option with the same key you passed.
      #
      #   q.choice :team, "Which team should handle this?", billing: "Payments", technical: "Bugs"
      #   q.choice :language, "Which language is this written in?", %i[english spanish other]
      #
      def choice(id, instructions, options = nil, **described)
        options = options.is_a?(Array) ? options.to_h { |option| [option, nil] } : (options || {}).merge(described)
        raise ArgumentError, "choice #{id.inspect} needs at least two options" if options.size < 2

        add id, Question.new(type: :choice, instructions: instructions, criteria: options)
      end

      # Adds a question that rates the state on ordered +levels+, lowest
      # first. Each level describes a concrete situation. The answer is a
      # probability-weighted position between the first and last level.
      #
      #   q.score :frustration, "How frustrated is the customer?", ["Calm", "Frustrated", "Very angry"]
      #
      def score(id, instructions, levels)
        raise ArgumentError, "score #{id.inspect} needs at least two levels" if Array(levels).size < 2

        add id, Question.new(type: :score, instructions: instructions, criteria: Array(levels))
      end

      # Returns whether no questions have been added.
      def empty?
        @questions.empty?
      end

      # Returns the questions as a Hash of id to Question.
      def to_h
        @questions.dup
      end

      private

      def add(id, question)
        raise ArgumentError, "question #{id.inspect} is already defined" if @questions.key?(id)

        @questions[id] = question
        self
      end
    end
  end
end
