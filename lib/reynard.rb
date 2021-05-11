# frozen_string_literal: true

# Reynard is a convenience class for configuring an HTTP request against an
# OpenAPI specification.
class Reynard
  autoload :Specification, 'reynard/specification'
  autoload :VERSION, 'reynard/version'
end
