# frozen_string_literal: true

require 'rack/utils'

class Reynard
  module Serializers
    # Reynard actually uses the request object to serialize the form data and write it directly
    # to the socket. MultipartFormData is used to set the correct headers and as a feature
    # switch the Reynard's request object.
    class MultipartFormData
      # We use all lowercase and no punctiation to be nice to other implementation.
      ALPHABET = ('a'..'z').to_a + ('0'..'9').to_a
      MULTIPART_BOUNDARY = 0.upto(69).map { ALPHABET.sample }.join.freeze

      attr_reader :data

      def initialize(data:)
        @data = data
      end

      def mime_type
        'multipart/form-data'
      end

      def headers
        { 'Content-Type' => %(#{mime_type}; boundary="#{multipart_boundary}") }
      end

      def multipart_boundary
        MULTIPART_BOUNDARY
      end
    end
  end
end
