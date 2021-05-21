# frozen_string_literal: true

class Reynard
  # Holds reference and object type for a schema in the API specification.
  class Schema
    attr_reader :node, :object_type

    def initialize(node:, object_type:)
      @node = node
      @object_type = object_type
    end
  end
end
