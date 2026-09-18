# frozen_string_literal: true

require 'ruby_llm'
require_relative 'typesafe/questions'
require_relative 'typesafe/evaluation'

module RubyLLM
  # Typed judgments from TypeSafe's System One models. Ask yes/no, choice,
  # and score questions about a state and get probabilities back:
  #
  #   evaluation = RubyLLM::Typesafe.evaluate("Help! My payouts have been failing for 3 days.") do |q|
  #     q.noul :urgent, "Does this convey urgency?"
  #     q.choice :team, "Which team should handle this?",
  #              billing: "Payments, invoicing, refunds",
  #              technical: "Bugs, outages, integrations"
  #     q.score :frustration, "How frustrated is the customer?", ["Calm", "Frustrated", "Very angry"]
  #   end
  #
  #   evaluation[:urgent].probability  # => 0.92
  #   evaluation[:team].option         # => :technical
  #   evaluation[:frustration].level   # => "Very angry"
  #
  module Typesafe
    # The model evaluate uses when none is given.
    DEFAULT_MODEL = 'jev-latest'

    # Evaluates +state+ against the questions the block adds and returns an
    # Evaluation. +state+ is a String, or a Hash or Array for structured
    # data. The block receives a Questions builder. Every question runs in
    # parallel against the same state and cannot see the other answers.
    # +context:+ takes a RubyLLM::Context to use its configuration.
    #
    #   RubyLLM::Typesafe.evaluate(ticket, model: "jev-1.13.0") { |q| q.noul :spam, "Is this spam?" }
    #
    def self.evaluate(state, model: DEFAULT_MODEL, context: nil)
      raise ArgumentError, 'evaluate requires a block that adds questions' unless block_given?

      questions = Questions.new
      yield questions
      raise ArgumentError, 'evaluate requires at least one question' if questions.empty?

      config = context&.config || RubyLLM.config
      model, provider = Models.resolve(model, provider: :typesafe, config: config)
      provider.evaluate(state, questions, model: model)
    end
  end
end
