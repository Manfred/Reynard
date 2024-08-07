# frozen_string_literal: true

class Reynard
  class Http
    # Wraps an HTTP response and returns an object when it can find a definition for the response
    # in the specification.
    class Response
      extend Forwardable
      def_delegators :@http_response, :code, :content_type, :[], :body

      def initialize(specification:, request_context:, response_context:, http_response:)
        @specification = specification
        @request_context = request_context
        @response_context = response_context
        @http_response = http_response
      end

      # True when the response code is in the 1xx range.
      def informational?
        code.start_with?('1')
      end

      # True when the response code is in the 2xx range.
      def success?
        code.start_with?('2')
      end

      # True when the response code is in the 3xx range.
      def redirection?
        code.start_with?('3')
      end

      # True when the response code is in the 4xx range.
      def client_error?
        code.start_with?('4')
      end

      # True when the response code is in the 5xx range.
      def server_error?
        code.start_with?('5')
      end

      # Returns the parsed response body.
      def parsed_body
        return @parsed_body if defined?(@parsed_body)

        @parsed_body = deserialize_body
      end

      # Instantiates an object based on the schema that fits the response.
      def object
        return @object if defined?(@object)

        @object = build_object
      end

      private

      def deserialize_body
        return if @http_response.body.to_s == ''

        deserializer_class.new(
          headers: @http_response,
          body: @http_response.body
        ).call
      end

      def deserializer_class
        @deserializer_class ||= pick_deserializer
      end

      def pick_deserializer
        mime_type = @http_response.content_type.to_s.split(';', 2)[0]
        if @response_context.deserializers.key?(mime_type)
          @response_context.deserializers.fetch(mime_type)
        else
          raise(
            KeyError,
            "No registered deserializer for the response mime type `#{mime_type}'."
          )
        end
      end

      def build_object
        return unless parsed_body

        media_type = @specification.media_type(
          @request_context.operation.node,
          @http_response.code,
          @http_response.content_type
        )
        if media_type
          build_object_with_media_type(media_type)
        else
          build_object_without_media_type
        end
      end

      def build_object_with_media_type(media_type)
        ObjectBuilder.new(
          schema: @specification.schema(media_type.node),
          response_context: @response_context,
          parsed_body: parsed_body
        ).call
      end

      def build_object_without_media_type
        # Try to parse the response and give up otherwise.
        Reynard::Model.new(parsed_body, @response_context)
      end
    end
  end
end
