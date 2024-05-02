# frozen_string_literal: true

class Reynard
  # Wraps the choice for a serializer request content type, and returns headers and a serializer
  # to generate a request body.
  SerializerSelection = Struct.new(
    :content_type,
    :serializer_class,
    keyword_init: true
  )
end
