# frozen_string_literal: true

PROVIDER = :typesafe
RERANK_MODELS = [{ provider: :typesafe, model: 'jev-latest' }].freeze
EVALUATION_MODELS = RERANK_MODELS

def each_model(models)
  models.each { |model_info| yield model_info[:provider], model_info[:model], model_info }
end
