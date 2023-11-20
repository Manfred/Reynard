# frozen_string_literal: true

require 'net/http'
require 'rack'

class Reynard
  class Http
    # Configures and performs an HTTP request.
    class Request
      attr_reader :uri

      def initialize(request_context:)
        @request_context = request_context
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
        { 'User-Agent' => Reynard.user_agent }.merge(request_context_headers)
      end

      def request_context_headers
        (@request_context.headers || {}).merge(conditional_request_headers)
      end

      def conditional_request_headers
        if @request_context.features&.include?(:conditional_requests)
          ConditionalRequest.new(
            request_path: uri.path, store: @request_context.store
          ).headers
        else
          {}
        end
      end

      def build_request
        request = request_class.new(uri, request_headers)
        if @request_context.body
          @request_context.logger&.debug { @request_context.body }
          request.body = @request_context.body
        end
        request
      end
    end
  end
end
