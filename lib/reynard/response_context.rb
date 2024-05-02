# frozen_string_literal: true

class Reynard
  # Value class for details about handling the response.
  ResponseContext = Struct.new(
    :logger,
    keyword_init: true
  ) do
  end
end
