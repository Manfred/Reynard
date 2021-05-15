# frozen_string_literal: true

class Reynard
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
