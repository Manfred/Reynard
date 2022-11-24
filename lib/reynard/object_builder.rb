# frozen_string_literal: true

require 'ostruct'

class Reynard
  # Defines dynamic classes based on schema and instantiates them for a response.
  class ObjectBuilder
    attr_reader :schema, :parsed_body

    def initialize(schema:, parsed_body:, model_name: nil)
      @schema = schema
      @parsed_body = parsed_body
      @model_name = model_name
    end

    def model_name
      @model_name || @schema.model_name
    end

    def model_class
      return @model_class if defined?(@model_class)

      @model_class =
        self.class.model_class_get(model_name) || self.class.model_class_set(model_name, schema)
    end

    def call
      case schema.type
      when 'object'
        model_class.new(parsed_body)
      when 'array'
        cast_array
      else
        parsed_body
      end
    end

    def self.model_class_get(model_name)
      Kernel.const_get("::Reynard::Models::#{model_name}")
    rescue NameError
      nil
    end

    def self.model_class_set(model_name, schema)
      if schema.type == 'array'
        array_model_class_set(model_name)
      else
        object_model_class_set(model_name, schema)
      end
    end

    def self.array_model_class_set(model_name)
      return Array unless model_name

      ::Reynard::Models.const_set(model_name, Class.new(Array))
    end

    def self.object_model_class_set(model_name, schema)
      return Reynard::Model unless model_name

      model_class = Class.new(Reynard::Model)
      model_class.schema = schema
      ::Reynard::Models.const_set(model_name, model_class)
    end

    private

    def cast_array
      return unless parsed_body

      item_schema = schema.item_schema
      array = model_class.new
      parsed_body.each do |item|
        array << self.class.new(
          schema: item_schema,
          parsed_body: item
        ).call
      end
      array
    end
  end
end
