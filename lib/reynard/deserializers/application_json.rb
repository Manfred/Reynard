# frozen_string_literal: true

class Reynard
  module Deserializers
    # Parses a JSON response body.
    class ApplicationJson
      def initialize(body:, **)
        @body = body
      end

      def call
        MultiJson.load(@body)
      end
    end
  end
end
