# ruby_llm-providers-typesafe

[TypeSafe](https://typesafe.ai) for [RubyLLM](https://rubyllm.com). TypeSafe's System One models, starting with Jev, answer typed questions about your data with calibrated probabilities instead of generated text.

## Installation

```ruby
gem 'ruby_llm-providers-typesafe'
```

```ruby
RubyLLM.configure do |config|
  config.typesafe_api_key = ENV['TYPESAFE_API_KEY']
end
```

Outside Bundler, load it with `require 'ruby_llm/providers/typesafe'`.

## Evaluate

Ask questions about a state, and get one typed answer per question:

```ruby
evaluation = RubyLLM::Typesafe.evaluate("Help! My payouts have been failing for 3 days.") do |q|
  q.noul :urgent, "Does this convey urgency?"
  q.choice :team, "Which team should handle this?",
           billing: "Payments, invoicing, refunds",
           technical: "Bugs, outages, integrations",
           sales: "Pricing, upgrades, new accounts"
  q.score :frustration, "How frustrated is the customer?", ["Calm", "Frustrated", "Very angry"]
end

evaluation[:urgent].probability    # => 0.95
evaluation[:urgent].yes?           # => true
evaluation[:team].option           # => :billing
evaluation[:team].probabilities    # => {technical: 0.15, billing: 0.85, sales: 0.0}
evaluation[:team].confidence       # => 0.77
evaluation[:frustration].score     # => 1.05
evaluation[:frustration].level     # => "Frustrated"
evaluation.model                   # => "jev-1.13.0"
evaluation.cost.total              # => 0.000016884
```

There are three question types:

* `noul` asks a yes/no question. Its answer is the probability of yes. Pass `yes:` and `no:` to describe what each answer means.
* `choice` picks one option. Pass descriptions as keywords or a Hash, or an Array of options that need none. The answer uses the keys you passed.
* `score` rates the state on ordered levels, lowest first. The answer can land between levels.

The state can be a String, or a Hash or Array for structured data. Refer to parts of it from your questions with backticked paths such as `` `ticket.messages[0].text` ``. Every question runs in parallel against the same state, so ask independent questions together.

`yes?` compares the probability to 0.5 by default. Choose thresholds from your own data with `yes?(threshold: 0.8)`, and use `confidence` to send uncertain choices and scores to a person. See TypeSafe's guides to [writing questions](https://docs.typesafe.ai/concepts/how-to-build-with-system-one) and [confidence](https://docs.typesafe.ai/confidence).

Evaluations default to `jev-latest`. Pin a version once you have tuned thresholds against it:

```ruby
RubyLLM::Typesafe.evaluate(ticket, model: "jev-1.13.0") { |q| q.noul :spam, "Is this message spam?" }
```

## Rerank

Jev also works with `RubyLLM.rerank`. Every document gets a relevance question in a single request, and its score is the probability that it helps answer the query:

```ruby
rerank = RubyLLM.rerank("What is the capital of the United States?",
                        ["Carson City is the capital of Nevada.",
                         "Washington, D.C. is the capital of the United States."],
                        model: "jev-latest", provider: :typesafe, top_n: 1)

rerank.results.first.document # => "Washington, D.C. is the capital of the United States."
```

The query and all documents share Jev's 32k-token state budget. Rerank a shortlist from a faster search, not a whole corpus.

## Development

```sh
bin/setup
bundle exec rake
```

Copy `.env.example` to `.env` and set `TYPESAFE_API_KEY` to record VCR cassettes. The first local run calls the API and records them; CI only replays committed cassettes. A failing live example deletes its cassette so the next run hits the API again.

`bundle exec rake models` refreshes `models.json` from TypeSafe's model listing. The listing returns aliases such as `jev-latest`; versioned ids such as `jev-1.13.0` are accepted without being listed.
