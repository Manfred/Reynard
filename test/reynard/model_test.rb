# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ModelTest < Reynard::Test
    def setup
      @model = Model.new(name: 'James', age: 12)
    end

    test 'responds to attributes' do
      assert @model.respond_to?(:name, private: false)
    end

    test 'does not respond to random attributes' do
      refute @model.respond_to?(:unknown, private: false)
    end

    test 'returns correct values for attributes' do
      assert_equal 'James', @model.name
      assert_equal 12, @model.age
    end
  end
end