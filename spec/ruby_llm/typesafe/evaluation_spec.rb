# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Typesafe::Evaluation, :live do
  include_context 'with configured RubyLLM'

  each_model(EVALUATION_MODELS) do |provider, model|
    it "#{provider}/#{model} answers noul, choice, and score questions" do
      evaluation = RubyLLM::Typesafe.evaluate('Help! My payouts have been failing for 3 days.', model: model) do |q|
        q.noul :urgent, 'Does this convey urgency?'
        q.choice :team, 'Which team should handle this?',
                 billing: 'Payments, invoicing, refunds',
                 technical: 'Bugs, outages, integrations',
                 sales: 'Pricing, upgrades, new accounts'
        q.score :frustration, 'How frustrated is the customer?', ['Calm', 'Frustrated', 'Very angry']
      end

      expect(evaluation[:urgent].probability).to be_between(0, 1)
      expect(evaluation[:team].probabilities.keys).to contain_exactly(:billing, :technical, :sales)
      expect(evaluation[:team].probabilities.values.sum).to be_within(0.01).of(1)
      expect(evaluation[:frustration].score).to be_between(0, 2)
      expect(evaluation[:frustration].probabilities.size).to eq(3)
      expect(evaluation.tokens.input).to be_positive
    end
  end
end
