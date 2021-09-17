# frozen_string_literal: true

class Reynard
  # Wraps the YAML representation of an OpenAPI specification.
  class Specification
    def initialize(filename:)
      @filename = filename
      @data = read
    end

    # Digs a value out of the specification, taking $ref into account.
    def dig(*path)
      dig_into(@data, @data, path.dup)
    end

    def servers
      dig('servers').map { |attributes| Server.new(attributes) }
    end

    def default_base_url
      servers.first&.url
    end

    # The specification tells us where a parameter should be included, they can be placed in path,
    # query, header, or cookie. In order to get them in the correct place, we group them by their
    # location.
    #
    #   build_grouped_params(operation_node, { 'q' => 'face' }) #=>
    #     { 'query' => { 'q' => 'face' } }
    def build_grouped_params(operation_node, params)
      return {} unless params

      GroupedParameters.new(dig(*operation_node, 'parameters'), params).to_h
    end

    # Returns a serialized body instance to serialize a request body and figure out the request
    # headers.
    def build_body(operation_node, data)
      SerializedBody.new(dig(*operation_node, 'requestBody', 'content'), data)
    end

    def operation(operation_name)
      dig('paths').each do |path, operations|
        operations.each do |verb, operation|
          return Operation.new(node: ['paths', path, verb]) if operation_name == operation['operationId']
        end
      end
      nil
    end

    def media_type(operation_node, response_code, media_type)
      responses = dig(*operation_node, 'responses')
      response_code = 'default' unless responses.key?(response_code)
      response, media_type = media_type_response(responses, response_code, media_type)
      return unless response

      MediaType.new(
        node: [*operation_node, 'responses', response_code, 'content', media_type],
        schema_name: schema_name(response)
      )
    end

    def media_type_response(responses, response_code, media_type)
      responses.dig(response_code, 'content').each do |expression, response|
        return response, expression if self.class.media_type_matches?(media_type, expression)
      end
      nil
    end

    def schema(media_type_node)
      schema = dig(*media_type_node, 'schema')
      return unless schema

      Schema.new(
        node: [*media_type_node, 'schema'],
        object_type: schema['type'],
        item_schema_name: item_schema_name(schema)
      )
    end

    def self.media_type_matches?(media_type, expression)
      return true unless media_type
      return true if expression == media_type

      false
    end

    private

    def read
      File.open(@filename, encoding: 'UTF-8') do |file|
        YAML.safe_load(file)
      end
    end

    def dig_into(data, cursor, path)
      while path.length.positive?
        cursor = cursor[path.first]
        return unless cursor

        path.shift
        next unless cursor.respond_to?(:key?) && cursor&.key?('$ref')

        # We currenly only supply references inside the document starting with #/.
        path = cursor['$ref'][2..].split('/') + path
        cursor = data
      end
      cursor
    end

    def schema_name(response)
      ref = response.dig('schema', '$ref')
      ref&.split('/')&.last
    end

    def item_schema_name(schema)
      ref = schema.dig('items', '$ref')
      ref&.split('/')&.last
    end

    def object_name(_schema)
      'Book'
    end
  end
end
