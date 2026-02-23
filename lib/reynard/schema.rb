# frozen_string_literal: true

class Reynard
  # Holds a references to a schema definition in the specification.
  class Schema
    autoload :ModelNaming, 'reynard/schema/model_naming'

    attr_reader :node, :namespace

    def initialize(specification:, node:, namespace: nil)
      @specification = specification
      @node = node
      @namespace = namespace
    end

    def type
      return @type if defined?(@type)

      @type = @specification.dig(*node, 'type')
    end

    def model_name
      @model_name || model_naming.model_name
    end

    # Returns the schema for items when the current schema is an array.
    def item_schema
      return unless type == 'array'

      self.class.new(
        specification: @specification,
        node: [*node, 'items'],
        namespace: [*namespace, model_name]
      )
    end

    # Returns the schema for a propery in the schema.
    def property_schema(name)
      property_node = [*node, 'properties', name.to_s]
      return unless @specification.dig(*property_node)

      self.class.new(
        specification: @specification,
        node: property_node,
        namespace: [*namespace, model_name]
      )
    end

    def self.determine_schema_type(schema)
      if schema.key?('type')
        schema['type']
      elsif schema.keys.intersect?(%w[allOf anyOf oneOf])
        'object'
      end
    end

    private

    def model_naming
      ModelNaming.new(specification: @specification, node: @node)
    end
  end
end
