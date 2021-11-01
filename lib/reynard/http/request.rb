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
        when 'put'
          build_http_put
        when 'patch'
          build_http_patch
        when 'delete'
          build_http_delete
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

      def build_http_put
        put = Net::HTTP::Put.new(uri, @request_context.headers)
        put.body = @request_context.body
        put
      end

      def build_http_patch
        patch = Net::HTTP::Patch.new(uri, @request_context.headers)
        patch.body = @request_context.body
        patch
      end

      def build_http_delete
        Net::HTTP::Delete.new(uri, @request_context.headers)
      end
    end
  end
end
