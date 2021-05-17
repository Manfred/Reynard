# frozen_string_literal: true

require 'net/http'
require 'rack'

class Reynard
  class Http
    # Configures and performs an HTTP request.
    class Request
      attr_reader :verb, :uri, :body, :params, :headers

      def initialize(verb, url:, **options)
        @verb = verb
        @uri = URI(url)
        @params = options[:params]
        @body = options[:body]
        @headers = options[:headers]
      end

      def perform
        build_http.request(build_request)
      end

      private

      def build_request
        case verb
        when 'get'
          build_http_get
        when 'post'
          build_http_post
        end
      end

      def build_http
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.set_debug_output($stderr) if ENV['DEBUG']
        http
      end

      def build_http_get
        Net::HTTP::Get.new(uri, headers)
      end

      def build_http_post
        post = Net::HTTP::Post.new(uri, headers)
        post.body = body
        post
      end
    end
  end
end
