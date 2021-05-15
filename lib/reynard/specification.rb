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

    def operation(operation_name)
      dig('paths').each do |path, operations|
        operations.each do |verb, operation|
          if operation_name == operation['operationId']
            return Operation.new(
              verb: verb,
              path: path,
              node: ['paths', path, verb]
            )
          end
        end
      end
      nil
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
  end
end
