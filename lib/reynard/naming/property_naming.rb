# frozen_string_literal: true

class Reynard
  module Naming
    # Transforms property names from payload to make them valid Ruby method names.
    class PropertyNaming
      attr_reader :exceptions

      def initialize(exceptions: {})
        @exceptions = exceptions
      end

      def call(property_name)
        @exceptions[property_name] || self.class.snake_case(property_name)
      end

      def self.snake_case(name)
        name
          .to_s
          .gsub(/([A-Z])(?=[A-Z][a-z])|([a-z\d])(?=[A-Z])/) do
            (Regexp.last_match(1) || Regexp.last_match(2)) << '_'
          end
          .tr("'\"-", '___')
          .downcase
      end
    end
  end
end
