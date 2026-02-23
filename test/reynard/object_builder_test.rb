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
        schema:,
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
        schema:,
        inflector: @inflector,
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
      @inflector = Inflector.new
    end

    test 'builds a singular record' do
      operation = @specification.operation('fetchAuthor')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      author = Reynard::ObjectBuilder.new(
        schema:,
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

  class ExternalRequestPathAndDeepRefsBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/external.yml'))
      @inflector = Inflector.new
    end

    test 'builds a singular record' do
      operation = @specification.operation('listAuthors')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      authors = Reynard::ObjectBuilder.new(
        schema:,
        inflector: @inflector,
        parsed_body: [
          { id: 42, name: 'Jerry Writer', bio: { age: 42 } }
        ]
      ).call
      assert_model_name('AuthorsCollection', authors)
      authors.each do |author|
        assert_model_name('Author', author)
        assert_equal 42, author.id
      end
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
        schema:,
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
        schema:,
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
          schema:,
          inflector: @inflector,
          parsed_body:
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
          schema:,
          inflector: @inflector,
          parsed_body:
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
        schema:,
        inflector: @inflector,
        parsed_body:
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

  class NamingObjectBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/naming.yml'))
      @inflector = Inflector.new
    end

    test 'builds objects for data in a large nested array of trees' do
      operation = @specification.operation('getSectors')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      record = Reynard::ObjectBuilder.new(
        schema:,
        inflector: @inflector,
        parsed_body: [
          {
            id: 76,
            name: 'Industry',
            subsectors: [
              {
                name: 'Light Industry',
                industry_groups: [
                  {
                    name: 'Electronics',
                    industries: [
                      {
                        name: 'Chip Manufacturing',
                        national_industries: [
                          {
                            label: 'chip-manu-gb'
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      ).call

      assert_model_name('SectorCollection', record)

      sector = record[0]
      assert_model_name('Sector', sector)

      assert_model_name('SubsectorsCollection', sector.subsectors)

      subsector = sector.subsectors[0]
      assert_model_name('Subsector', subsector)

      assert_model_name('IndustryGroupsCollection', subsector.industry_groups)

      industry_group = subsector.industry_groups[0]
      assert_model_name('IndustryGroup', industry_group)

      assert_model_name('IndustriesCollection', industry_group.industries)

      industry = industry_group.industries[0]
      assert_model_name('Industry', industry)

      assert_model_name('NationalIndustriesCollection', industry.national_industries)

      national_industry = industry.national_industries[0]
      assert_model_name('NationalIndustry', national_industry)
    end
  end

  class PolymorphicBuilderTest < Reynard::Test
    Response = Struct.new(:body, keyword_init: true)

    def setup
      @specification = Specification.new(filename: fixture_file('openapi/polymorphic.yml'))
      @inflector = Inflector.new
    end

    test 'handles oneOf and allOf' do
      operation = @specification.operation('getPets')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      collection = Reynard::ObjectBuilder.new(
        schema:,
        inflector: @inflector,
        parsed_body: [
          {
            'pet_type' => 'Dog',
            'tail' => true
          }
        ]
      ).call

      assert_equal(1, collection.size)
      record = collection[0]

      assert_model_name('Pet', record)
      assert_equal 'Dog', record.pet_type
      assert record.tail
    end

    test 'handles anyOf' do
      operation = @specification.operation('getStatus')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      record = Reynard::ObjectBuilder.new(
        schema:,
        inflector: @inflector,
        parsed_body: {
          'status' => 'online',
          'description' => 'Everything works'
        }
      ).call

      assert_model_name('Statu', record)
      assert_equal 'online', record.status
      assert_equal 'Everything works', record.description
    end
  end
end
