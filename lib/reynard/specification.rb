# frozen_string_literal: true

class Reynard
  # Wraps the YAML representation of an OpenAPI specification.
  class Specification
    def initialize(filename:)
      @filename = filename
      @data = read
    end

    def dig(*path)
      @data.dig(*path)
    end

    private

    def read
      File.open(@filename, encoding: 'UTF-8') do |file|
        YAML.safe_load(file)
      end
    end
  end
end
