# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ModelTest < Reynard::Test
    def setup
      @model = Model.new(
        {
          'name' => 'James',
          'age' => 12,
          'nickname' => nil,
          'subscribed' => false,
          'address' => {
            'zipcode' => '66232A'
          }
        }
      )
    end

    test 'responds to attributes' do
      assert @model.respond_to?(:name, private: false)
      assert @model.respond_to?(:nickname, private: false)
      assert @model.respond_to?(:subscribed, private: false)
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
      assert_nil @model.nickname
      assert_equal false, @model.subscribed
    end

    test 'allows access to attributes through [] accessor' do
      assert_equal 'James', @model['name']
    end

    test 'does not build a model for nested resources' do
      assert_kind_of(Hash, @model.address)
    end
  end

  class AttributeNameModelTest < Reynard::Test
    class Author < Model; end

    def setup
      Author.inflector.snake_cases(
        {
          '1st-class' => 'first_class',
          '--allow' => 'allowed',
          'startGRID' => 'start_grid'
        }
      )
      @author = Author.new(
        {
          'first_name' => 'James',
          '1st-class' => 'false',
          '--allow' => false,
          'startGRID' => nil
        }
      )
    end

    test 'responds to regular attributes' do
      assert @author.respond_to?(:first_name)
    end

    test 'responds to mapped properties' do
      assert @author.respond_to?(:first_class)
      assert @author.respond_to?(:allowed)
      assert @author.respond_to?(:start_grid)
    end

    test 'returns correct values for regular attributes' do
      assert_equal 'James', @author.first_name
    end

    test 'returns correct values for mapped properties' do
      assert_equal 'false', @author.first_class
      assert_equal false, @author.allowed
      assert_nil @author.start_grid
    end

    test 'allows access to attributes through [] accessor' do
      assert_equal 'James', @author['first_name']
      assert_equal 'false', @author['1st-class']
    end
  end

  class AttributeNameWithInflectionsModelTest < Reynard::Test
    def setup
      @model = Model.new(
        'firstName' => 'James',
        'LastName' => 'Jameson',
        'ORIGINAL' => 'original',
        'ignore__Experience' => 'experience',
        '__pragma' => 'keep',
        'first5' => 'true',
        '12RulesFOR' => 'mist'
      )
    end

    test 'responds to normalized attributes' do
      %i[
        first_name
        last_name
        original
        ignore__experience
        __pragma
        first5
        12_rules_for
      ].each do |attribute_name|
        assert(
          @model.respond_to?(attribute_name, private: false),
          "Expected #{@model.inspect} to respond to #{attribute_name}"
        )
      end
    end

    test 'returns correct values for normalized attributes' do
      assert_equal 'James', @model.first_name
      assert_equal 'keep', @model.__pragma
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
      @model = @model_class.new({ 'name' => 'Erebus', 'author' => { 'name' => 'Palin' } })
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
