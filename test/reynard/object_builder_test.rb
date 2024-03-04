# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ObjectBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
      @inflector = Inflector.new
    end

    test 'builds a collection' do
      operation = @specification.operation('listBooks')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      books = Reynard::ObjectBuilder.new(
        schema: schema,
        inflector: @inflector,
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
        inflector: @inflector,
        parsed_body: { id: 42, name: 'Black Science' }
      ).call
      assert_model_name('Book', book)
      assert_equal 42, book.id
      assert_equal 'Black Science', book.name
    end

    test "builds a singular record with schema having no title property set" do
      @specification = Specification.new(filename: fixture_file('openapi/no_title.yml'))
      operation = @specification.operation('sampleChapter')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      chapter = Reynard::ObjectBuilder.new(
        schema: schema,
        inflector: @inflector,
        parsed_body: { number: 1, title: 'Echoes of the Void' }
      ).call
      assert_model_name('Schema', chapter)
      assert_equal 1, chapter.number
      assert_equal 'Echoes of the Void', chapter.title
    end

    test "raises a TypeError exception when building a collection with schema having no title property set for the list and its elements" do
      @specification = Specification.new(filename: fixture_file('openapi/no_title.yml'))
      operation = @specification.operation('listChapters')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      assert_raises(
        TypeError,
        "no implicit conversion of Hash into Integer"
      ) do
        Reynard::ObjectBuilder.new(
          schema: schema,
          inflector: @inflector,
          parsed_body: [{ number: 1, title: 'Echoes of the Void' }, { number: 2, title: 'The Alchemy of Shadows' }]
        ).call
      end
    end

    test "raises a TypeError exception when building a singular record with schema having no title property set after building a collection with schema having no $ref property set" do
      @specification = Specification.new(filename: fixture_file('openapi/no_title.yml'))
      operation = @specification.operation('listSubChapters')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      sub_chapters = Reynard::ObjectBuilder.new(
        schema: schema,
        inflector: @inflector,
        parsed_body: [{ number: 1, title: 'Whispers from the Abyss' }, { number: 2, title: 'Harmonics of the Unknown' }]
      ).call
      assert_model_name('Schema', sub_chapters)

      operation = @specification.operation('sampleChapter')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      assert_raises(
        TypeError,
        "no implicit conversion of Hash into Integer"
      ) do
        Reynard::ObjectBuilder.new(
          schema: schema,
          inflector: @inflector,
          parsed_body: { number: 1, title: 'Echoes of the Void' }
        ).call
      end
    end

    test "raises an ArgumentError exception when building a collection after building a single record with schema having no title property set" do
      @specification = Specification.new(filename: fixture_file('openapi/no_title.yml'))
      operation = @specification.operation('sampleChapter')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      chapter = Reynard::ObjectBuilder.new(
        schema: schema,
        inflector: @inflector,
        parsed_body: { number: 1, title: 'Echoes of the Void' }
      ).call
      assert_model_name('Schema', chapter)

      operation = @specification.operation('listSubChapters')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      assert_raises(
        ArgumentError,
        "wrong number of arguments (given 0, expected 1)"
      ) do
        Reynard::ObjectBuilder.new(
          schema: schema,
          inflector: @inflector,
          parsed_body: [{ number: 1, title: 'Whispers from the Abyss' }, { number: 2, title: 'Harmonics of the Unknown' }]
        ).call
      end
    end
  end

  class ExternalObjectBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/external.yml'))
      @inflector = Inflector.new
    end

    test 'builds a singular record' do
      operation = @specification.operation('fetchAuthor')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      author = Reynard::ObjectBuilder.new(
        schema: schema,
        inflector: @inflector,
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
      @inflector = Inflector.new
    end

    test 'builds a collection' do
      operation = @specification.operation('listISBN')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      collection = Reynard::ObjectBuilder.new(
        schema: schema,
        inflector: @inflector,
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
      @inflector = Inflector.new
    end

    test 'builds a singular record' do
      operation = @specification.operation('updateRoot')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      record = Reynard::ObjectBuilder.new(
        schema: schema,
        inflector: @inflector,
        parsed_body: { name: '😇' }
      ).call
      assert_model_name('AFRootWithInThe', record)
      assert_equal '😇', record.name
    end
  end

  class BadTypeObjectBuilderTest < Reynard::Test
    def setup
      @inflector = Inflector.new
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
          inflector: @inflector,
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
          inflector: @inflector,
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
      @inflector = Inflector.new
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
        inflector: @inflector,
        parsed_body: parsed_body
      ).call
      assert_model_name('Library', library)
      assert_kind_of(Array, library.books)
      library.books.each do |book|
        assert_model_name('Book', book)
        assert_model_name('Author', book.author)
      end

      assert_equal 'Borne', library.books[1].author.name
    end
  end
end
