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
        object_type: 'object',
        item_schema_name: nil
      )
    end

    test 'returns its node' do
      assert_equal @node, @schema.node
    end

    test 'returns its object type' do
      assert_equal 'object', @schema.object_type
    end

    test 'does not return an item schema name' do
      assert_nil @schema.item_schema_name
    end
  end

  class CollectionSchemaTest < Reynard::Test
    def setup
      @node = %w[
        paths
        /books
        get
        responses
        200
        content
        application/json
        schema
      ]
      @schema = Schema.new(
        node: @node,
        object_type: 'array',
        item_schema_name: 'Book'
      )
    end

    test 'returns its node' do
      assert_equal @node, @schema.node
    end

    test 'returns its object type' do
      assert_equal 'array', @schema.object_type
    end

    test 'returns its item schema name' do
      assert_equal 'Book', @schema.item_schema_name
    end
  end
end
