# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class SchemaTest < Reynard::Test
    test 'uses object schema type for object schemas' do
      assert_equal('object', Schema.determine_schema_type({ 'type' => 'object' }))
    end

    test 'uses array schema type for array schemas' do
      assert_equal('array', Schema.determine_schema_type({ 'type' => 'array' }))
    end

    test 'uses object schema type for allOf' do
      assert_equal('object', Schema.determine_schema_type({ 'allOf' => {} }))
    end

    test 'uses object schema type for anyOf' do
      assert_equal('object', Schema.determine_schema_type({ 'anyOf' => {} }))
    end

    test 'uses object schema type for oneOf' do
      assert_equal('object', Schema.determine_schema_type({ 'oneOf' => {} }))
    end

    test 'does not return a schema type for unsupported schemas' do
      assert_nil Schema.determine_schema_type({})
    end
  end

  class SingularTopLevelSchemaTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
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
        specification: @specification,
        node: @node
      )
    end

    test 'returns its node' do
      assert_equal @node, @schema.node
    end

    test 'returns its type' do
      assert_equal 'object', @schema.type
    end

    test 'formats a model name and namespace' do
      assert_equal 'Book', @schema.model_name
      assert_nil @schema.namespace
    end

    test 'does not return an item schema' do
      assert_nil @schema.item_schema
    end

    test 'returns a schema for its properties' do
      schema = @schema.property_schema('id')
      assert_equal 'integer', schema.type
      assert_equal 'Id', schema.model_name
    end

    test 'does not return a schema for an unknown property' do
      assert_nil @schema.property_schema('unknown')
    end
  end

  class PluralTopLevelSchemaTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
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
        specification: @specification,
        node: @node
      )
    end

    test 'returns its node' do
      assert_equal @node, @schema.node
    end

    test 'returns its type' do
      assert_equal 'array', @schema.type
    end

    test 'formats a model name and namespace' do
      assert_equal 'BooksCollection', @schema.model_name
      assert_nil @schema.namespace
    end

    test 'returns its item schema' do
      schema = @schema.item_schema
      assert_equal 'object', schema.type
      assert_equal 'Book', schema.model_name
    end

    test 'does not return a schema for an unknown property' do
      assert_nil @schema.property_schema('unknown')
    end
  end

  class NestedSchemaTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/nested.yml'))
      @node = %w[
        paths
        /library
        get
        responses
        200
        content
        application/json
        schema
      ]
      @schema = Schema.new(
        specification: @specification,
        node: @node
      )
    end

    test 'returns its node' do
      assert_equal @node, @schema.node
    end

    test 'returns its type' do
      assert_equal 'object', @schema.type
    end

    test 'formats a model name and namespace' do
      assert_equal 'Library', @schema.model_name
      assert_nil @schema.namespace
    end

    test 'does not return an item schema' do
      assert_nil @schema.item_schema
    end

    test 'digs into its property schemas' do
      schema = @schema.property_schema('books')
      assert_equal 'array', schema.type
      assert_equal 'BooksCollection', schema.model_name
      assert_equal %w[Library], schema.namespace

      schema = schema.item_schema
      assert_equal 'object', schema.type
      assert_equal 'Book', schema.model_name
      assert_equal %w[Library BooksCollection], schema.namespace

      schema = schema.property_schema('author')
      assert_equal 'object', schema.type
      assert_equal 'Author', schema.model_name
      assert_equal %w[Library BooksCollection Book], schema.namespace

      schema = schema.property_schema('name')
      assert_equal 'string', schema.type
      assert_equal 'Name', schema.model_name
      assert_equal %w[Library BooksCollection Book Author], schema.namespace
    end
  end
end
