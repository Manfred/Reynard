# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ModelTest < Reynard::Test
    test 'formats an exception message for unusuable attributes' do
      assert_equal(
        "Models must be intialized with an enumerable object that behaves like a Hash, got: `[]'" \
        ". Usually this means the schema defined in the OpenAPI specification doesn't fit the " \
        'payload in the HTTP response.',
        Reynard::Model.attributes_error_message([])
      )
    end

    test 'raises an exception when attempting to build and instance with a nil value' do
      error = assert_raises(ArgumentError) do
        Model.new(nil, ResponseContext.build)
      end
      assert(
        error.message.start_with?(
          "Models must be intialized with an enumerable object that behaves like a Hash, got: `nil'"
        )
      )
    end

    test 'raises an exception when attempting to build and instance with a scalar value' do
      assert_raises(ArgumentError) { Model.new(nil) }
      assert_raises(ArgumentError) { Model.new(false) }
      assert_raises(ArgumentError) { Model.new(12) }
    end
  end

  class EmptyModelTest < Reynard::Test
    def setup
      @model = Model.new({}, ResponseContext.build)
    end

    test 'knows it is empty' do
      assert @model.empty?
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
  end

  class AttributesModelTest < Reynard::Test
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
        },
        ResponseContext.build
      )
    end

    test 'knows it is not empty' do
      refute @model.empty?
    end

    test 'responds to attributes' do
      assert @model.respond_to?(:name, private: false)
      assert @model.respond_to?(:nickname, private: false)
      assert @model.respond_to?(:display, private: false)
      assert @model.respond_to?(:subscribed, private: false)
    end

    test 'can never respond to an attribute that is an invalid instance variable' do
      refute @model.respond_to?(:unknown?, private: false)
    end

    test 'does not respond to random attributes' do
      refute @model.respond_to?(:unknown, private: false)
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

    test 'try returns a value when the attribute exists and the value is set' do
      assert_equal 'James', @model.try(:name)
    end

    test 'try returns nil when the attribute does not exist' do
      assert_nil @model.try(:location)
    end

    test 'pretty-prints a model' do
      out = StringIO.new
      q = PP.new(out, 79)
      q.guard_inspect_key { q.pp @model }
      q.flush
      assert(out.string.start_with?('#<Reynard::Model'))
    end
  end
end
