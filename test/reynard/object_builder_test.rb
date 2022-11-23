# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ObjectBuilderTest < Reynard::Test
    Response = Struct.new(:body, keyword_init: true)

    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
    end

    test 'builds a collection' do
      operation = @specification.operation('listBooks')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      collection = Reynard::ObjectBuilder.new(
        media_type:,
        schema:,
        http_response: Response.new(
          body: '[{"id":42,"name":"Black Science"},{"id":51,"name":"Dead Astronauts"}]'
        )
      ).call
      assert_kind_of(Reynard::ObjectBuilder.model_class('Books', 'array'), collection)

      assert_equal 2, collection.length

      record = collection[0]
      assert_kind_of(Reynard::ObjectBuilder.model_class('Book', 'array'), record)
      assert_equal 42, record.id
      assert_equal 'Black Science', record.name

      record = collection[1]
      assert_kind_of(Reynard::ObjectBuilder.model_class('Book', 'array'), record)
      assert_equal 51, record.id
      assert_equal 'Dead Astronauts', record.name
    end

    test 'builds a singular record' do
      operation = @specification.operation('fetchBook')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      record = Reynard::ObjectBuilder.new(
        media_type:,
        schema:,
        http_response: Response.new(body: '{"id":42,"name":"Black Science"}')
      ).call
      assert_kind_of(Reynard::ObjectBuilder.model_class('Book', 'object'), record)
      assert_equal 42, record.id
      assert_equal 'Black Science', record.name
    end
  end

  class ExternalObjectBuilderTest < Reynard::Test
    Response = Struct.new(:body, keyword_init: true)

    def setup
      @specification = Specification.new(filename: fixture_file('openapi/external.yml'))
    end

    test 'builds a singular record' do
      operation = @specification.operation('fetchAuthor')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      record = Reynard::ObjectBuilder.new(
        media_type:,
        schema:,
        http_response: Response.new(body: '{"id":42,"name":"Jerry Writer"}')
      ).call
      assert_kind_of(Reynard::ObjectBuilder.model_class('Author', 'object'), record)
      assert_equal 42, record.id
      assert_equal 'Jerry Writer', record.name
    end
  end

  class TitledObjectBuilderTest < Reynard::Test
    Response = Struct.new(:body, keyword_init: true)

    def setup
      @specification = Specification.new(filename: fixture_file('openapi/titled.yml'))
    end

    test 'builds a collection' do
      operation = @specification.operation('listISBN')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      collection = Reynard::ObjectBuilder.new(
        media_type:,
        schema:,
        http_response: Response.new(
          body: '[{"isbn":"9781534307407","title":"Black Science Premiere Hardcover Volume 1 Remastered Edition (Black Science Omnibus, 1)"}]'
        )
      ).call
      assert_kind_of(Array, collection)

      record = collection[0]
      assert_kind_of(Reynard::ObjectBuilder.model_class('ISBN', 'object'), record)
      assert_equal '9781534307407', record.isbn
      assert_equal(
        'Black Science Premiere Hardcover Volume 1 Remastered Edition (Black Science Omnibus, 1)',
        record.title
      )
    end
  end

  class WeirdObjectBuilderTest < Reynard::Test
    Response = Struct.new(:body, keyword_init: true)

    def setup
      @specification = Specification.new(filename: fixture_file('openapi/weird.yml'))
    end

    test 'builds a singular record' do
      operation = @specification.operation('updateRoot')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      record = Reynard::ObjectBuilder.new(
        media_type:,
        schema:,
        http_response: Response.new(body: '{"name":"😇"}')
      ).call
      assert_kind_of(Reynard::ObjectBuilder.model_class('AFRootWithInThe', 'object'), record)
      assert_equal '😇', record.name
    end
  end
end
