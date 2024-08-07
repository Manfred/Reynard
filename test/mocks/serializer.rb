# frozen_string_literal: true

module Mocks
  class Serializer
    attr_reader :data

    def initialize
      @data = []
    end

    def mime_type
      'application/mocks'
    end

    def headers
      { 'Content-Type' => mime_type }
    end

    def body
      MultiJson.dump(@data)
    end
  end
end
