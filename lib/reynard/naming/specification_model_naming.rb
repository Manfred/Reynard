# frozen_string_literal: true

class Reynard
  module Naming
    # Attempts to create a unique name for a model based on the specification.
    class SpecificationModelNaming
      def initialize(specification:, node:)
        @specification = specification
        @node = node
      end

      def model_name
        title_model_name || ref_model_name || node_model_name
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

      def self.singularize(name)
        name.chomp('s')
      end

      private

      # Returns a model name when it was explicitly set using the title property in the specification.
      def title_model_name
        title = @specification.dig(*@node, 'title')
        return unless title

        self.class.title_model_name(title)
      end

      # Returns a model name based on the schema's $ref value, usually this contains a usable
      # identifier at the end like /books.yml or /Books.
      def ref_model_name
        parent = @specification.dig(*@node[..-2])
        ref = parent.dig('schema', '$ref') || parent.dig('items', '$ref')
        return unless ref

        self.class.ref_model_name(ref)
      end

      # Returns a model name based on the node path to schema in the specification.
      def node_model_name
        self.class.title_model_name(node_path_name.capitalize.gsub(/[_-]/, ' '))
      end

      def node_path_name
        if node_anyonymous?
          request_path_model_name
        elsif @node.last == 'items'
          # Use the property name as the model name for its items, for example in the case of
          # schema > properties > birds > items => bird.
          self.class.singularize(@node.at(-2))
        else
          # Usually this means we are dealing with a property's name a not a model, for example in
          # the case of schema > properties > color => color.
          @node.last
        end
      end

      # Returns true when the node path doesn't have identifyable segments other than the request
      # path for the resource.
      #
      # For example, when the last part of the path looks like this:
      #   get > responses > 200 > content > application|json > schema
      def node_anyonymous?
        @node.last == 'schema' || @node.last(2) == %w[schema items]
      end

      # Finds the first segment starting from the end of the request path that is not a parameter
      # and transforms that to make a model name.
      #
      # For example:
      #   /books/{id} => "book"
      def request_path_model_name
        self.class.singularize(@node[1].split('/').reverse.find { |part| !part.start_with?('{') })
      end
    end
  end
end
