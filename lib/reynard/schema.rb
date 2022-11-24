# frozen_string_literal: true

class Reynard
  # Holds a references to a schema definition in the specification.
  class Schema
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
      return @model_name if defined?(@model_name)

      @model_name = find_model_name
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
      property_node = [*node, 'properties', name]
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

    # Returns a model name based on the schema's title or $ref.
    def find_model_name
      title_model_name || ref_model_name || node_model_name
    end

    def title_model_name
      title = @specification.dig(*node, 'title')
      return unless title

      self.class.title_model_name(title)
    end

    def ref_model_name
      parent = @specification.dig(*node[..-2])
      ref = parent.dig('schema', '$ref') || parent.dig('items', '$ref')
      return unless ref

      self.class.ref_model_name(ref)
    end

    def node_model_name
      self.class.title_model_name(node_property_name.capitalize.gsub(/[_-]/, ' '))
    end

    def node_property_name
      node.last == 'items' ? node.at(-2).chomp('s') : node.last
    end
  end
end
