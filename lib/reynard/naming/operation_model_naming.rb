# frozen_string_literal: true

class Reynard
  module Naming
    # Formats a name based on the name of the operation.
    class OperationModelNaming
      def initialize(specification:, node:)
        @specification = specification
        @node = node
      end

      def array_item?
        @node.last == 'items'
      end

      def property?
        @node[-2] == 'properties'
      end

      def model_name
        if array_item?
          item_model_name
        elsif property?
          @node.last.capitalize
        else
          "#{operation_model_name}Response"
        end
      end

      private

      def item_model_name
        if @node[-3] == 'properties'
          "#{@node[-2].capitalize}Item"
        else
          "#{operation_model_name}Item"
        end
      end

      def operation_id
        return @operation_id if defined?(@operation_id)

        @operation_id =
          if operation_node
            @specification.dig(*operation_node)['operationId']
          else
            @node.last
          end
      end

      def operation_node
        operation_node_index = @node.index('responses')
        return unless operation_node_index

        @node[0..operation_node_index - 1]
      end

      def operation_model_name
        "#{operation_id[0].upcase}#{operation_id[1..]}"
      end
    end
  end
end
