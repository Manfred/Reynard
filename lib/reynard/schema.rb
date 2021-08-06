# frozen_string_literal: true

class Reynard
  # Holds reference and object type for a schema in the API specification.
  class Schema
    attr_reader :node, :object_type, :item_schema_name

    def initialize(node:, object_type:, item_schema_name:)
      @node = node
      @object_type = object_type
      @item_schema_name = item_schema_name
    end
  end
end
