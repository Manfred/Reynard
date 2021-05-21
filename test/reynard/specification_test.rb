# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class SpecificationTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
    end

    test 'initializes with an OpenAPI filename' do
      assert_equal 'Library', @specification.dig('info', 'title')
    end

    test 'digs into the specification through references' do
      assert_equal(
        %w[id name],
        @specification.dig('components', 'schemas', 'Books', 'items', 'required')
      )
    end

    test 'digs repeatedly into the same specification without breaking it' do
      assert_equal(
        'books',
        @specification.dig('tags', 0, 'name')
      )
      assert_equal(
        'books',
        @specification.dig('tags', 0, 'name')
      )
    end

    test 'finds an operation based on their operation id' do
      operation = @specification.operation('listBooks')
      assert_equal(%w[paths /books get], operation.node)
      assert_equal('/books', operation.path)
      assert_equal('get', operation.verb)

      operation = @specification.operation('fetchBook')
      assert_equal(%w[paths /books/{id} get], operation.node)
      assert_equal('/books/{id}', operation.path)
      assert_equal('get', operation.verb)
    end

    test 'does not find an operation with a non-existent operation id' do
      assert_nil @specification.operation('non-existent')
    end

    test 'finds a media type relative to an operation' do
      operation = @specification.operation('listBooks')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      assert_equal(%w[paths /books get responses 200 content application/json], media_type.node)
      assert_equal('200', media_type.response_code)
      assert_equal('application/json', media_type.media_type)

      operation = @specification.operation('searchBooks')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      assert_equal(
        %w[paths /search/books get responses 200 content application/json],
        media_type.node
      )
      assert_equal('200', media_type.response_code)
      assert_equal('application/json', media_type.media_type)
    end

    test 'finds the default media type for unknown response code' do
      operation = @specification.operation('listBooks')
      media_type = @specification.media_type(operation.node, '100', 'application/json')
      assert_equal(
        %w[paths /books get responses default content application/json],
        media_type.node
      )
      assert_equal('default', media_type.response_code)
      assert_equal('application/json', media_type.media_type)
    end

    test 'does not find media type for unknown media type' do
      operation = @specification.operation('listBooks')
      assert_nil @specification.media_type(operation.node, '200', 'application/octet-stream')
    end

    test 'finds a schema based relative to a media type' do
      operation = @specification.operation('listBooks')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      assert_equal(
        %w[paths /books get responses 200 content application/json schema],
        schema.node
      )
      assert_equal('array', schema.object_type)

      operation = @specification.operation('fetchBook')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      assert_equal(
        %w[paths /books/{id} get responses 200 content application/json schema],
        schema.node
      )
      assert_equal('object', schema.object_type)
    end
  end
end
