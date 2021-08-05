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
      response_code = responses.key?(response_code) ? response_code : 'default'
      response = responses.dig(response_code, 'content', media_type)
      return unless response

      MediaType.new(
        node: [*operation_node, 'responses', response_code, 'content', media_type],
        schema_name: schema_name(response)
      )
    end

    def schema(media_type_node)
      schema = dig(*media_type_node, 'schema')
      return unless schema

      Schema.new(node: [*media_type_node, 'schema'], object_type: schema['type'])
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

    def object_name(_schema)
      'Book'
    end
  end
end
