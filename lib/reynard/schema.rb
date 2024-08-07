# frozen_string_literal: true

class Reynard
  # Holds a references to a schema definition in the specification.
  class Schema
    attr_reader :node, :specification

    def initialize(specification:, node:)
      @specification = specification
      @node = node
    end

    def type
      return @type if defined?(@type)

      @type = @specification.dig(*@node, 'type')
    end

    def properties
      return @properties if defined?(@properties)

      @properties = build_properties
    end

    def items_schema
      return unless type == 'array'
      return unless @specification.dig(*@node, 'items')

      self.class.new(
        specification: @specification,
        node: [*@node, 'items']
      )
    end

    def to_h
      @specification.dig(*node)
    end

    private

    def build_properties
      specification = @specification.dig(*@node, 'properties')
      return unless specification

      properties = {}
      specification.each_key do |property_name|
        properties[property_name] = Property.new(
          name: property_name,
          type: @specification.dig(*@node, 'properties', property_name, 'type'),
          schema: object_schema(property_name)
        )
      end
      properties
    end

    def object_schema(property_name)
      return unless type == 'object'

      self.class.new(
        specification: @specification,
        node: [*@node, 'properties', property_name]
      )
    end
  end
end
