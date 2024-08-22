# frozen_string_literal: true

class Reynard
  # Groups parameters based on the parameters specification.
  class GroupedParameters
    def initialize(specification:, node:, params:)
      @specification = specification
      @node = node
      @params = params
    end

    def constraints
      return @constraints if defined?(@constraints)

      @constraints = actualize(*@node, 'parameters') || actualize(*@node[..-2], 'parameters') || {}
    end

    def to_h
      @params.each_with_object({}) do |(name, value), grouped|
        group_name = constraints.dig(name, 'in') || 'query'
        grouped[group_name] ||= {}
        grouped[group_name].merge!({ name => value })
      end
    end

    private

    def actualize(*node)
      parameters = @specification.dig(*node)
      return unless parameters

      pivot = {}
      parameters.each.with_index do |attributes, index|
        attributes = @specification.dig(*node, index) if attributes.key?('$ref')
        pivot[attributes['name']] = attributes
      end
      pivot
    end
  end
end
