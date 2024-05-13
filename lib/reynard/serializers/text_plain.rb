# frozen_string_literal: true

class Reynard
  module Serializers
    # Generates a plain text request body.
    class TextPlain
      def initialize(data:)
        @data = data
      end

      def mime_type
        'text/plain'
      end

      def headers
        { 'Content-Type' => mime_type.to_s }
      end

      def body
        @data.to_s
      end
    end
  end
end
