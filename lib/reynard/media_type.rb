# frozen_string_literal: true

class Reynard
  # Holds media type, response code, and node reference to a response in the API specification.
  class MediaType
    attr_reader :media_type, :code, :node

    def initialize(media_type:, code:, node:)
      @media_type = media_type
      @code = code
      @node = node
    end
  end
end
