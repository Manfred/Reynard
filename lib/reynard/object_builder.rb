# frozen_string_literal: true

require 'ostruct'

class Reynard
  # Defines dynamic classes based on schema and instantiates them for a response.
  class ObjectBuilder
    def initialize(media_type:, schema:, http_response:)
      @media_type = media_type
      @schema = schema
      @http_response = http_response
    end

    def object_class
      if @media_type.schema_name
        self.class.model_class(@media_type.schema_name, @schema.object_type)
      elsif @schema.object_type == 'array'
        Array
      else
        Reynard::Model
      end
    end

    def item_object_class
      if @schema.item_schema_name
        self.class.model_class(@schema.item_schema_name, 'object')
      else
        Reynard::Model
      end
    end

    def call
      if @schema.object_type == 'array'
        array = object_class.new
        data.each { |attributes| array << item_object_class.new(attributes) }
        array
      else
        object_class.new(data)
      end
    end

    def data
      @data ||= MultiJson.load(@http_response.body)
    end

    def self.model_class(name, object_type)
      model_class_get(name) || model_class_set(name, object_type)
    end

    def self.model_class_get(name)
      Kernel.const_get("::Reynard::Models::#{name}")
    rescue NameError
      nil
    end

    def self.model_class_set(name, object_type)
      if object_type == 'array'
        Reynard::Models.const_set(name, Class.new(Array))
      else
        Reynard::Models.const_set(name, Class.new(Reynard::Model))
      end
    end
  end
end
