# frozen_string_literal: true

class Reynard
  module Serializers
    # Generates a JSON request body.
    class ApplicationJson
      def initialize(data:)
        @data = data
      end

      def mime_type
        'application/json'
      end

      def headers
        { 'Content-Type' => mime_type.to_s }
      end

      def body
        MultiJson.dump(@data)
      end
    end
  end
end
