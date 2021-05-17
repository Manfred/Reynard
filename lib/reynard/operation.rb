# frozen_string_literal: true

class Reynard
  # Holds the verb, request path, and node reference to an operation in the API specification.
  class Operation
    DEFAULT_MEDIA_TYPE = 'application/json'

    attr_reader :verb, :path, :node

    def initialize(verb:, path:, node:)
      @verb = verb
      @path = path
      @node = node
    end
  end
end
