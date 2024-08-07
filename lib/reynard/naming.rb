# frozen_string_literal: true

class Reynard
  # Contains implementation related to naming properties and models.
  module Naming
    # Property naming.

    autoload :PropertyNaming, 'reynard/naming/property_naming'

    # Model naming.

    autoload :NodeModelNaming, 'reynard/naming/node_model_naming'
    autoload :OperationModelNaming, 'reynard/naming/operation_model_naming'
    autoload :SpecificationModelNaming, 'reynard/naming/specification_model_naming'

    # Model registries.

    autoload :KeyedModelRegistry, 'reynard/naming/keyed_model_registry'
    autoload :ModelRegistry, 'reynard/naming/model_registry'
  end
end
