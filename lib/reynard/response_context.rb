# frozen_string_literal: true

class Reynard
  # Value class for details about handling the response.
  ResponseContext = Struct.new(
    :logger,
    :deserializers,
    keyword_init: true
  ) do
    def copy(**properties)
      copy = dup
      properties.each { |attribute, value| copy.send("#{attribute}=", value) }
      copy
    end
  end
end
