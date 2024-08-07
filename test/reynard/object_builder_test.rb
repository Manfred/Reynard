# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ObjectBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
      @response_context = ResponseContext.build
    end

    test 'builds a collection' do
      operation = @specification.operation('listBooks')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      books = Reynard::ObjectBuilder.new(
        schema: schema,
        response_context: @response_context,
        parsed_body: [{ id: 42, name: 'Black Science' }, { id: 51, name: 'Dead Astronauts' }]
      ).call

      assert_kind_of(Array, books)
      assert_equal 2, books.length

      book = books[0]
      assert_model_name('Book', book)
      assert_equal 42, book.id
      assert_equal 'Black Science', book.name

      book = books[1]
      assert_model_name('Book', book)
      assert_equal 51, book.id
      assert_equal 'Dead Astronauts', book.name
    end

    test 'builds a singular record' do
      operation = @specification.operation('fetchBook')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      book = Reynard::ObjectBuilder.new(
        schema: schema,
        response_context: @response_context,
        parsed_body: { id: 42, name: 'Black Science' }
      ).call
      assert_model_name('Book', book)
      assert_equal 42, book.id
      assert_equal 'Black Science', book.name
    end
  end

  class ExternalObjectBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/external.yml'))
      @response_context = ResponseContext.build
    end

    test 'builds a singular record' do
      operation = @specification.operation('fetchAuthor')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      author = Reynard::ObjectBuilder.new(
        schema: schema,
        response_context: @response_context,
        parsed_body: {
          id: 42, name: 'Jerry Writer', bio: { age: 42 }
        }
      ).call

      assert_model_name('Author', author)
      assert_equal 42, author.id
      assert_equal 'Jerry Writer', author.name
      assert_equal 42, author.bio.age
    end
  end

  class TitledObjectBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/titled.yml'))
      @response_context = ResponseContext.build
    end

    test 'builds a collection' do
      operation = @specification.operation('listISBN')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      collection = Reynard::ObjectBuilder.new(
        schema: schema,
        response_context: @response_context,
        parsed_body: [
          {
            isbn: '9781534307407',
            title: 'Black Science Premiere Hardcover Volume 1 Remastered Edition (Black Science Omnibus, 1)'
          }
        ]
      ).call

      assert_kind_of(Array, collection)
      isbn = collection[0]
      assert_model_name('ISBN', isbn)
      assert_equal '9781534307407', isbn.isbn
      assert_equal(
        'Black Science Premiere Hardcover Volume 1 Remastered Edition (Black Science Omnibus, 1)',
        isbn.title
      )
    end
  end

  class WeirdObjectBuilderTest < Reynard::Test
    Response = Struct.new(:body, keyword_init: true)

    def setup
      @specification = Specification.new(filename: fixture_file('openapi/weird.yml'))
      @response_context = ResponseContext.build
    end

    test 'builds a singular record' do
      operation = @specification.operation('updateRoot')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      record = Reynard::ObjectBuilder.new(
        schema: schema,
        response_context: @response_context,
        parsed_body: { name: '😇' }
      ).call
      assert_model_name('AFRootWithInThe', record)
      assert_equal '😇', record.name
    end
  end

  class BadTypeObjectBuilderTest < Reynard::Test
    def setup
      @response_context = ResponseContext.build
    end

    test 'payload contains an object instead of an array' do
      specification = Specification.new(filename: fixture_file('openapi/titled.yml'))

      operation = specification.operation('listISBN')
      media_type = specification.media_type(operation.node, '200', 'application/json')
      schema = specification.schema(media_type.node)
      parsed_body = { 'message' => 'Something went wrong' }
      exception = assert_raises(ArgumentError) do
        Reynard::ObjectBuilder.new(
          schema: schema,
          response_context: @response_context,
          parsed_body: parsed_body
        ).call
      end
      assert_equal(
        Reynard::Model.attributes_error_message(parsed_body.to_a.first),
        exception.message
      )
    end

    test 'payload that contains an array instead of an object' do
      specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
      operation = specification.operation('fetchBook')
      media_type = specification.media_type(operation.node, '200', 'application/json')
      schema = specification.schema(media_type.node)
      parsed_body = []
      exception = assert_raises(ArgumentError) do
        Reynard::ObjectBuilder.new(
          schema: schema,
          response_context: @response_context,
          parsed_body: parsed_body
        ).call
      end
      assert_equal(
        Reynard::Model.attributes_error_message(parsed_body),
        exception.message
      )
    end
  end

  class NestedObjectBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/nested.yml'))
      @response_context = ResponseContext.build
    end

    test 'builds a collection' do
      parsed_body = {
        'id' => 881_234,
        'name' => 'Mainz Public Library',
        'books' => [
          {
            'id' => 42,
            'name' => 'Black Science',
            'author' => { 'name' => 'Remender' }
          },
          {
            'id' => 51,
            'name' => 'Dead Astronauts',
            'author' => { 'name' => 'Borne' }
          }
        ]
      }
      operation = @specification.operation('showLibrary')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      library = Reynard::ObjectBuilder.new(
        schema: schema,
        response_context: @response_context,
        parsed_body: parsed_body
      ).call
      assert_model_name('Library', library)
      assert_kind_of(Array, library.books)

      library.books.each do |book|
        assert_model_name('Library::Book', book)
        assert_model_name('Library::Book::Author', book.author)
      end
      assert_equal 'Borne', library.books[1].author.name
    end
  end
end
