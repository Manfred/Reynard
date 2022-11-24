# frozen_string_literal: true

class Reynard
  # Holds node reference a media type in the API specification.
  class MediaType
    attr_reader :node

    def initialize(node:)
      @node = node
    end
  end
end
