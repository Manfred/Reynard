# frozen_string_literal: true

class Reynard
  # Value class for details about handling the response.
  ResponseContext = Struct.new(
    :logger,
    :deserializers,
    :model_registry,
    :model_naming,
    :property_naming,
    keyword_init: true
  ) do
    def copy(**properties)
      copy = dup
      properties.each { |attribute, value| copy.send("#{attribute}=", value) }
      copy
    end

    def self.build
      ResponseContext.new(
        deserializers: Reynard.deserializers.dup,
        model_registry: Reynard.model_registry,
        model_naming: Reynard.model_naming,
        property_naming: Reynard.property_naming
      )
    end
  end
end
