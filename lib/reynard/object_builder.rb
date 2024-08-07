# frozen_string_literal: true

class Reynard
  # Defines dynamic classes based on schema and instantiates them for a response.
  class ObjectBuilder
    attr_reader :schema, :parsed_body

    def initialize(schema:, response_context:, parsed_body:, namespace: nil)
      @schema = schema
      @response_context = response_context
      @parsed_body = parsed_body
      @namespace = namespace
    end

    def model_name
      @model_name || model_naming(schema.node).model_name
    end

    def model_class
      return @model_class if defined?(@model_class)

      @model_class = fetch_class
    end

    def call
      return unless @parsed_body

      case @schema.type
      when 'object'
        model_class.new(@parsed_body, @response_context)
      when 'array'
        cast_array
      else
        Reynard::Model.new(@parsed_body, @response_context)
      end
    end

    private

    def model_naming(node)
      @response_context.model_naming.new(specification: schema.specification, node: node)
    end

    def fetch_class
      model_registry_get || model_registry_set
    end

    def model_registry_get
      @response_context.model_registry.get(model_name: model_name, namespace: @namespace)
    end

    def model_registry_set
      @response_context.model_registry.set(
        model_name: model_name, model: build_model_class, namespace: @namespace
      )
    end

    def build_model_class
      model_class = ClassBuilder.new(schema: @schema, response_context: @response_context).call
      model_class.name = model_name if model_class.respond_to?(:name=)
      model_class.namespace = model_namespace if model_class.respond_to?(:namespace=)
      model_class
    end

    def cast_array
      array = model_class.new
      @parsed_body.each do |parsed|
        array << ObjectBuilder.new(
          schema: @schema.items_schema,
          response_context: @response_context,
          parsed_body: parsed,
          namespace: model_namespace
        ).call
      end
      array
    end

    def model_namespace
      (@namespace.to_s.split('::') + [model_name]).join('::')
    end
  end
end
