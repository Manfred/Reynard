# frozen_string_literal: true

class Reynard
  class Http
    # Wraps an HTTP response and returns an object when it can find a definition for the response
    # in the specification.
    class Response
      extend Forwardable
      def_delegators :@http_response, :code, :content_type, :[]

      def initialize(specification:, inflector:, request_context:, http_response:)
        @specification = specification
        @inflector = inflector
        @request_context = request_context
        @http_response = http_response
        handle_conditional_response
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

      def body
        return @body if defined?(@body)

        @http_response.body
      end

      # Returns the parsed response body.
      def parsed_body
        return @parsed_body if defined?(@parsed_body)

        @parsed_body = MultiJson.load(body)
      end

      # Instantiates an object based on the schema that fits the response.
      def object
        return @object if defined?(@object)

        @object = build_object
      end

      private

      def handle_conditional_response
        return unless @request_context.features&.include?(:conditional_requests)

        case @http_response.code
        when '200'
          conditional_response.remember
        when '304'
          body = conditional_response.retrieve
          @body = body if body
        end
      end

      def conditional_response
        @conditional_response ||= ConditionalResponse.new(
          request_path: @request_context.path,
          store: @request_context.store,
          http_response: @http_response
        )
      end

      def build_object
        media_type = @specification.media_type(
          @request_context.operation.node,
          @http_response.code == '304' ? '200' : @http_response.code,
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
          inflector: @inflector,
          parsed_body: parsed_body
        ).call
      end

      def build_object_without_media_type
        # Try to parse the response as JSON and give up otherwise.
        Reynard::Model.new(MultiJson.load(body))
      rescue StandardError
        body
      end
    end
  end
end
