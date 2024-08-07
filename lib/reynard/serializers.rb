# frozen_string_literal: true

class Reynard
  # Contains built-in serializer classes.
  module Serializers
    autoload :ApplicationJson, 'reynard/serializers/application_json'
    autoload :MultipartFormData, 'reynard/serializers/multipart_form_data'
    autoload :TextPlain, 'reynard/serializers/text_plain'
  end
end
