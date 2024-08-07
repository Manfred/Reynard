# frozen_string_literal: true

class Reynard
  class Specification
    # Finds nodes in a specification that match a query.
    class Finder
      def initialize(specification:, query:)
        @specification = specification
        @query = query
      end

      def find_each(&block)
        find_into([], &block)
      end

      private

      def find_into(path, &block)
        data = @specification.dig(*path)

        yield path if data.respond_to?(:key?) && (data.key?('type') && (@query.type == data['type']))

        return unless data.respond_to?(:each_key)

        data.each_key do |key|
          find_into([*path, key], &block)
        end
      end
    end
  end
end
