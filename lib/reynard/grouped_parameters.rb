# frozen_string_literal: true

class Reynard
  # Groups parameters based on the parameters specification.
  class GroupedParameters
    def initialize(specification, params)
      @specification = pivot(specification)
      @params = params
    end

    def to_h
      @params.each_with_object({}) do |(name, value), grouped|
        group_name = @specification.dig(name, 'in') || 'query'
        grouped[group_name] ||= {}
        grouped[group_name].merge!({ name => value })
      end
    end

    private

    def pivot(specification)
      return {} unless specification

      specification.each_with_object({}) do |attribute, pivot|
        pivot[attribute['name']] = attribute
      end
    end
  end
end
