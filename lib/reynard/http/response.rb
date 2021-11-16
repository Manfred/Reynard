# frozen_string_literal: true

class Reynard
  class Http
    # Wraps an HTTP response and returns an object when it can find a definition for the response
    # in the specification.
    class Response
      extend Forwardable
      def_delegators :@http_response, :code, :content_type, :[], :body

      def initialize(specification:, request_context:, http_response:)
        @specification = specification
        @request_context = request_context
        @http_response = http_response
      end

      # Instantiates an object based on the schema that fits the response.
      def object
        return @object if defined?(@object)

        @object = build_object
      end

      private

      def build_object
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
          media_type: media_type,
          schema: @specification.schema(media_type.node),
          http_response: @http_response
        ).call
      end

      def build_object_without_media_type
        # Try to parse the response as JSON and give up otherwise.
        OpenStruct.new(MultiJson.load(@http_response.body))
      rescue StandardError
        @http_response.body
      end
    end
  end
end
