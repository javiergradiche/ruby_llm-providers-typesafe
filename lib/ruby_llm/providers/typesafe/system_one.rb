# frozen_string_literal: true

require_relative 'system_one/models'
require_relative 'system_one/evaluations'
require_relative 'system_one/rerank'

module RubyLLM
  module Providers
    class Typesafe < Provider
      # The System One wire format: a state and a map of typed questions go
      # in, one typed answer per question comes back.
      class SystemOne < Protocol
        include Models
        include Evaluations
        include Rerank
      end
    end
  end
end
