# frozen_string_literal: true

class Reynard
  # Holds node reference and schema name to a media type in the API specification.
  class MediaType
    attr_reader :node, :schema_name

    def initialize(node:, schema_name:)
      @node = node
      @schema_name = schema_name
    end

    def media_type
      @node[6]
    end

    def response_code
      @node[4]
    end
  end
end
