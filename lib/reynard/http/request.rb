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
        Reynard.http.request(uri, build_request)
      end

      private

      def build_request
        case @request_context.verb
        when 'get'
          build_http_get
        when 'post'
          build_http_post
        end
      end

      def build_http_get
        Net::HTTP::Get.new(uri, @request_context.headers)
      end

      def build_http_post
        post = Net::HTTP::Post.new(uri, @request_context.headers)
        post.body = @request_context.body
        post
      end
    end
  end
end
