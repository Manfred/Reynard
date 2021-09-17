# frozen_string_literal: true

class Reynard
  # Serializes a request body and returns headers appropriate for the request.
  class SerializedBody
    def initialize(content, data)
      @content = content
      @data = data
    end

    def content_type
      'application/json'
    end

    def headers
      { 'Content-Type' => content_type }
    end

    def to_s
      MultiJson.dump(@data)
    end
  end
end
