# frozen_string_literal: true

class Reynard
  class Specification
    # Describes a query for a node in a specification.
    class Query
      attr_reader :type

      def initialize(type: nil)
        @type = type
      end
    end
  end
end
