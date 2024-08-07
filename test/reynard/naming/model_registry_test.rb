# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  module Naming
    class ModelRegistryTest < Reynard::Test
      def setup
        @model_registry = ModelRegistry.new
        @model = Class.new
      end

      test 'registers a model with a simple class name' do
        @model_registry.set(model_name: 'Author', model: @model)
        assert_equal(@model, @model_registry.get(model_name: 'Author'))
      end

      test 'registers a model with a namespaced class name' do
        @model_registry.set(model_name: 'Library::Book::Author', model: @model)
        assert_equal(@model, @model_registry.get(model_name: 'Library::Book::Author'))
      end

      test 'registers a model with a shared namespaced' do
        book = Class.new
        library = Class.new
        author = Class.new

        @model_registry.set(model_name: 'Library::Book', model: book)
        @model_registry.set(model_name: 'Library', model: library)
        @model_registry.set(model_name: 'Library::Book::Author', model: author)

        assert_equal(library, @model_registry.get(model_name: 'Library'))
        assert_equal(book, @model_registry.get(model_name: 'Library::Book'))
        assert_equal(author, @model_registry.get(model_name: 'Library::Book::Author'))
      end
    end
  end
end
