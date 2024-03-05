# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ModelTest < Reynard::Test
    def setup
      @model = Model.new(
        {
          'name' => 'James',
          'age' => 12,
          'display' => true,
          'nickname' => nil,
          'subscribed' => false,
          'address' => {
            'zipcode' => '66232A'
          }
        }
      )
    end

    test 'formats an exception message for unusuable attributes' do
      assert_equal(
        "Models must be intialized with an enumerable object that behaves like a Hash, got: `[]'" \
        ". Usually this means the schema defined in the OpenAPI specification doesn't fit the " \
        'payload in the HTTP response.',
        Reynard::Model.attributes_error_message([])
      )
    end

    test 'knows it is not empty' do
      refute @model.empty?
    end

    test 'returns a useful value when inspected' do
      assert_match(/#<Reynard::Model:0x.+>/, @model.inspect)
    end

    test 'it is not nil' do
      refute @model.nil?
    end

    test 'responds to attributes' do
      assert @model.respond_to?(:name, private: false)
      assert @model.respond_to?(:nickname, private: false)
      assert @model.respond_to?(:display, private: false)
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
      assert_equal true, @model.display
      assert_nil @model.nickname
      assert_equal false, @model.subscribed
    end

    test 'allows access to attributes through [] accessor' do
      assert_equal 'James', @model['name']
    end

    test 'does not build a model for nested resources' do
      assert_kind_of(Hash, @model.address)
    end

    test 'does not attempt to build an object out of nil values' do
      assert_nil Model.cast('name', nil)
    end

    test 'try returns a value when the attribute exists and the value is set' do
      assert_equal 'James', @model.try(:name)
    end

    test 'try returns nil when the attribute does not exist' do
      assert_nil @model.try(:location)
    end

    test 'raises an exception when attempting to build and instance with a nil value' do
      assert_raises(
        ArgumentError,
        "Models must be initialized with an enumerable object that behaves like a hash, got: `nil'"
      ) do
        Model.new(nil)
      end
    end

    test 'raises an exception when attempting to build and instance with a scalar value' do
      assert_raises(ArgumentError) { Model.new(nil) }
      assert_raises(ArgumentError) { Model.new(false) }
      assert_raises(ArgumentError) { Model.new(12) }
    end
  end

  class EmptyModelTest < Reynard::Test
    def setup
      @model = Model.new({})
    end

    test 'knows it is empty' do
      assert @model.empty?
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

      @model_class = ::Reynard::Models.const_set('Book', Class.new(Reynard::Model))
      @model_class.schema = @schema
      @model = @model_class.new({ 'name' => 'Erebus', 'author' => { 'name' => 'Palin' } })
    end

    test 'returns a useful value when inspected' do
      assert_match(/#<Reynard::Models::Book:0x.+>/, @model.inspect)
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
      assert_kind_of(Reynard::Models::LibraryAuthor, @model.author)
      assert_equal 'Palin', @model.author.name
    end

    test 'does not attempt to build an object out of nil values' do
      assert_nil @model_class.cast('author', nil)
    end
  end
end
