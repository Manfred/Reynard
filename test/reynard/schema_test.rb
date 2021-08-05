# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class SchemaTest < Reynard::Test
    def setup
      @node = %w[
        paths
        /books/{id}
        get
        responses
        200
        content
        application/json
        schema
      ]
      @schema = Schema.new(
        node: @node,
        object_type: 'object'
      )
    end

    test 'returns its node' do
      assert_equal @node, @schema.node
    end

    test 'returns its object type' do
      assert_equal 'object', @schema.object_type
    end
  end
end
