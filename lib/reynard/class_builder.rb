# frozen_string_literal: true

class Reynard
  # Builds a model class with accessors and metadata based on the schema from the specification.
  class ClassBuilder
    def initialize(schema:, response_context:)
      @schema = schema
      @response_context = response_context
    end

    def accessors
      @schema.properties.map do |_, property|
        self.class.property_accessors(@response_context.property_naming, property)
      end.compact.join("\n")
    end

    def call
      case @schema.type
      when 'object'
        to_object_class
      when 'array'
        to_array_class
      end
    end

    def self.property_accessors(property_naming, property)
      property_name = property_naming.call(property.name)
      case property.type
      when 'array'
        array_property_accessor(property_name, property)
      when 'object'
        object_property_accessor(property_name, property)
      else
        scalar_property_accessor(property_name, property)
      end
    end

    def self.array_property_accessor(property_name, property)
      sanitized_property_name = sanitize_name(property.name)
      <<~PROPERTY
        def #{property_name}
          return @#{sanitized_property_name} if defined?(@#{sanitized_property_name})

          property = self.class.properties.fetch("#{sanitized_property_name}")
          @#{sanitized_property_name} = @attributes["#{sanitized_property_name}"]&.map do |values|
            ObjectBuilder.new(
              schema: property.schema.items_schema,
              response_context: @response_context,
              parsed_body: values,
              namespace: self.class.namespace
            ).call
          end
        end
      PROPERTY
    end

    def self.object_property_accessor(property_name, property)
      sanitized_property_name = sanitize_name(property.name)
      <<~PROPERTY
        def #{property_name}
          return @#{sanitized_property_name} if defined?(@#{sanitized_property_name})

          property = self.class.properties.fetch("#{sanitized_property_name}")
          @#{sanitized_property_name} = ObjectBuilder.new(
            schema: property.schema,
            response_context: @response_context,
            parsed_body: @attributes["#{sanitized_property_name}"],
            namespace: self.class.namespace
          ).call
        end
      PROPERTY
    end

    def self.scalar_property_accessor(property_name, property)
      sanitized_property_name = sanitize_name(property.name)
      <<~PROPERTY
        def #{property_name}
          @attributes["#{sanitized_property_name}"]
        end
      PROPERTY
    end

    def self.sanitize_name(name)
      name.to_s.gsub(/["]/, '\"')
    end

    private

    def to_object_class
      model_class = Class.new(Reynard::Model)
      model_class.properties = @schema.properties
      model_class.class_eval(accessors, __FILE__)
      model_class
    end

    def to_array_class
      Class.new(Reynard::Collection)
    end
  end
end
