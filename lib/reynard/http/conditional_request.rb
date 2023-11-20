# frozen_string_literal: true

require 'digest/sha1'

class Reynard
  class Http
    # Finds header values for a conditional request.
    class ConditionalRequest
      def initialize(request_path:, store:)
        @request_path = request_path
        @store = store
      end

      def headers
        {
          'If-None-Match' => previous['Etag'],
          'If-Modified-Since' => previous['Last-Modified']
        }.compact
      end

      def self.digest(input)
        Digest::SHA1.hexdigest(input).scan(/\A(.{4})(.{4})(.+)\Z/)[0].join('/')
      end

      private

      def previous
        return @previous if defined?(@previous)

        json = @store.read(headers_store_key)
        @previous = json ? MultiJson.load(json) : {}
      end

      def headers_store_key
        "#{self.class.digest(@request_path)}.info"
      end
    end
  end
end
