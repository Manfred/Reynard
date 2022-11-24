# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ModelTest < Reynard::Test
    def setup
      @model = Model.new(name: 'James', age: 12, address: { zipcode: '66232A' })
    end

    test 'responds to attributes' do
      assert @model.respond_to?(:name, private: false)
    end

    test 'does not respond to random attributes' do
      refute @model.respond_to?(:unknown, private: false)
    end

    test 'can never respond to an attribute that is an invalid instance variable' do
      refute @model.respond_to?(:unknown?, private: false)
    end

    test 'raises NoMethodError calling an attribute method that is an invalid instance variable' do
      assert_raises(NoMethodError) { @model.unknown? }
    end

    test 'returns correct values for attributes' do
      assert_equal 'James', @model.name
      assert_equal 12, @model.age
    end

    test 'does not build a model for nested resources' do
      assert_kind_of(Hash, @model.address)
    end
  end

  class SchemaModelTest < Reynard::Test
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
        properties
        books
        items
      ]
      @schema = Schema.new(
        specification: @specification,
        node: @node
      )
      @model_class = Class.new(Reynard::Model)
      @model_class.schema = @schema
      @model = @model_class.new(name: 'Erebus', author: { name: 'Palin' })
    end

    test 'responds to attributes' do
      assert @model.respond_to?(:name, private: false)
    end

    test 'does not respond to random attributes' do
      refute @model.respond_to?(:unknown, private: false)
    end

    test 'can never respond to an attribute that is an invalid instance variable' do
      refute @model.respond_to?(:unknown?, private: false)
    end

    test 'raises NoMethodError calling an attribute method that is an invalid instance variable' do
      assert_raises(NoMethodError) { @model.unknown? }
    end

    test 'returns correct values for attributes' do
      assert_equal 'Erebus', @model.name
    end

    test 'builds a model for nested resources' do
      assert_kind_of(Reynard::Models::Author, @model.author)
      assert_equal 'Palin', @model.author.name
    end
  end
end
