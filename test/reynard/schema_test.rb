# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class SchemaTest < Reynard::Test
    test 'formats a model name based on the title specification' do
      {
        'AdministrationAgreement' => 'AdministrationAgreement',
        'Library' => 'Library',
        'ISBN' => 'ISBN',
        ' A %2F root with 🚕 in the ' => 'AFRootWithInThe'
      }.each do |model_name, expected|
        assert_equal expected, Schema.title_model_name(model_name)
      end
    end

    test 'does not return a model name based on a missing title' do
      assert_nil Schema.title_model_name(nil)
    end

    test 'formats a model name based on a ref to a schema' do
      {
        '#/components/schemas/Library' => 'Library',
        './schemas/author.yml' => 'Author',
        '#/components/schemas/%20howdy%E2%9A%A0%EF%B8%8F.Pardner' => 'HowdyPardner',
        '#/components/schemas/Service.Subscription' => 'ServiceSubscription'
      }.each do |ref, expected|
        assert_equal expected, Schema.ref_model_name(ref)
      end
    end

    test 'does not return a model name based on a missing ref' do
      assert_nil Schema.ref_model_name(nil)
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
      assert_equal 'Books', @schema.model_name
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
      assert_equal 'Books', schema.model_name
      assert_equal %w[Library], schema.namespace

      schema = schema.item_schema
      assert_equal 'object', schema.type
      assert_equal 'Book', schema.model_name
      assert_equal %w[Library Books], schema.namespace

      schema = schema.property_schema('author')
      assert_equal 'object', schema.type
      assert_equal 'Author', schema.model_name
      assert_equal %w[Library Books Book], schema.namespace

      schema = schema.property_schema('name')
      assert_equal 'string', schema.type
      assert_equal 'Name', schema.model_name
      assert_equal %w[Library Books Book Author], schema.namespace
    end
  end
end
