# frozen_string_literal: true

require 'net/http'
require 'rack'

class Reynard
  class Http
    # Configures and performs an HTTP request.
    class Request
      MULTIPART_FORM_DATA = 'multipart/form-data'

      attr_reader :uri

      def initialize(request_context:, serializer_selection:)
        @request_context = request_context
        @serializer_selection = serializer_selection
        @uri = URI(@request_context.url)
      end

      def perform
        @request_context.logger&.info { "#{@request_context.verb.upcase} #{uri}" }
        Reynard.http.request(uri, build_request)
      end

      private

      def request_class
        Net::HTTP.const_get(@request_context.verb.capitalize)
      end

      def request_headers
        {
          'User-Agent' => Reynard.user_agent
        }
          .merge(serializer&.headers || {})
          .merge(@request_context.headers || {})
      end

      def build_request
        request = request_class.new(uri, request_headers)
        return request unless @request_context.body

        if @serializer_selection&.content_type == MULTIPART_FORM_DATA
          request.set_form(
            serializer.data,
            serializer.mime_type,
            boundary: serializer.multipart_boundary
          )
        elsif serializer
          write_serializer_body(request)
        else
          write_serializer_params(request)
        end

        request
      end

      def write_serializer_body(request)
        @request_context.logger&.debug { @request_context.body }
        request.body = serializer.body
      end

      def write_serializer_params(request)
        @request_context.logger&.debug { @request_context.body }
        request.body = @request_context.body
      end

      def serializer
        return @serializer if defined?(@serializer)

        @serializer = build_serializer
      end

      def build_serializer
        return nil unless @serializer_selection&.serializer_class

        @serializer_selection.serializer_class.new(data: @request_context.body)
      end
    end
  end
end
