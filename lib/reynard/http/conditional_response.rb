# frozen_string_literal: true

require 'digest/sha1'

class Reynard
  class Http
    # Stores response headers and response body when the response contains an entity tag.
    class ConditionalResponse
      def initialize(request_path:, store:, http_response:)
        @request_path = request_path
        @store = store
        @http_response = http_response
      end

      def remember
        return unless @http_response['Etag']

        @store.write(headers_store_key, MultiJson.dump(remember_headers))
        @store.write(body_store_key, @http_response.body)
      end

      def retrieve
        @store.read(body_store_key)
      end

      def self.digest(input)
        Digest::SHA1.hexdigest(input).scan(/\A(.{4})(.{4})(.+)\Z/)[0].join('/')
      end

      private

      def headers_store_key
        "#{self.class.digest(@request_path)}.info"
      end

      def body_store_key
        "#{self.class.digest(@request_path)}.data"
      end

      def remember_headers
        {
          'Etag' => @http_response['Etag'],
          'Last-Modified' => @http_response['Last-Modified']
        }.compact
      end
    end
  end
end
