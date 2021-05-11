# frozen_string_literal: true

class Reynard
  # Wraps the YAML representation of an OpenAPI specification.
  class Specification
    def initialize(filename:)
      @filename = filename
      @data = read
    end

    # Digs a value out of the specification, taking $ref into account.
    #
    # rubocop:disable Metrics/MethodLength
    def dig(*path)
      current = @data
      rest = path.dup
      while rest.length.positive?
        current = current[rest.first]
        return unless current

        rest.shift
        next unless current.respond_to?(:key?) && current&.key?('$ref')

        # We currenly only supply references inside the document starting with #/.
        rest = current['$ref'][2..].split('/') + rest
        current = @data
      end
      current
    end
    # rubocop:enable Metrics/MethodLength

    private

    def read
      File.open(@filename, encoding: 'UTF-8') do |file|
        YAML.safe_load(file)
      end
    end
  end
end
