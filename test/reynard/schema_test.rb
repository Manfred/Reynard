# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
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

    test 'returns its properties' do
      assert_equal(%w[id name tag], @schema.properties.values.map(&:name))
      assert_equal(%w[integer string string], @schema.properties.values.map(&:type))
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

    test 'does not return properties' do
      assert_nil @schema.properties
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

    test 'returns its properties' do
      assert_equal(%w[id name books], @schema.properties.values.map(&:name))
      assert_equal(%w[integer string array], @schema.properties.values.map(&:type))
    end
  end
end
