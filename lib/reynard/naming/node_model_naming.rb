# frozen_string_literal: true

class Reynard
  module Naming
    # Formats a name based on the name of the node.
    class NodeModelNaming
      def initialize(specification:, node:)
        @specification = specification
        @node = node
      end

      def model_name
        @node.join("\x1e")
      end
    end
  end
end
