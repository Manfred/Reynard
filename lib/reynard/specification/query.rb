class Reynard
  class Specification
    class Query
      attr_reader :type

      def initialize(type: nil)
        @type = type
      end
    end
  end
end
