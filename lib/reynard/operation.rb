# frozen_string_literal: true

class Reynard
  # Holds the node reference to an operation in the API specification.
  class Operation
    DEFAULT_MEDIA_TYPE = 'application/json'

    attr_reader :node

    def initialize(node:)
      @node = node
    end

    def path
      @node[1]
    end

    def verb
      @node[2]
    end
  end
end
