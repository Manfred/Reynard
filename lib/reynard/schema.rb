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

    def self.title_model_name(model_name)
      return unless model_name

      model_name
        .gsub(/[^[:alpha:]]/, ' ')
        .gsub(/\s{2,}/, ' ')
        .gsub(/(\s+)([[:alpha:]])/) { Regexp.last_match(2).upcase }
        .strip
    end

    # Extracts a model name from a ref when there is a usable value.
    #
    #   ref_model_name("#/components/schemas/Library") => "Library"
    def self.ref_model_name(ref)
      return unless ref

      normalize_ref_model_name(ref.split('/')&.last)
    end

    def self.normalize_ref_model_name(model_name)
      # 1. Unescape encoded characters to create an UTF-8 string
      # 2. Remove extensions for regularly used external schema files
      # 3. Replace all non-alphabetic characters with a space (not allowed in Ruby constant)
      # 4. Camelcase
      Rack::Utils.unescape_path(model_name)
                 .gsub(/(.yml|.yaml|.json)\Z/, '')
                 .gsub(/[^[:alpha:]]/, ' ')
                 .gsub(/(\s+)([[:alpha:]])/) { Regexp.last_match(2).upcase }
                 .gsub(/\A(.)/) { Regexp.last_match(1).upcase }
    end

    private

    def model_naming
      ModelNaming.new(specification: @specification, node: @node)
    end
  end
end
