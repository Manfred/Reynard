# frozen_string_literal: true

require 'ostruct'

class Reynard
  # Defines dynamic classes based on schema and instantiates them for a response.
  class ObjectBuilder
    def initialize(media_type:, schema:, http_response:)
      @media_type = media_type
      @schema = schema
      @http_response = http_response
    end

    # Object.const_set(@media_type.schema_name, Class.new(Reynard::Model))
    def object_class
      if @media_type.schema_name
        self.class.model_class(@media_type.schema_name)
      else
        OpenStruct
      end
    end

    def call
      case @media_type.media_type
      when 'application/json'
        object_class.new(MultiJson.load(@http_response.body))
      else
        FailedRequest.new
      end
    end

    def self.model_class(name)
      Reynard::Models.const_get(name)
    rescue NameError
      Reynard::Models.const_set(name, Class.new(Reynard::Model))
    end
  end
end
