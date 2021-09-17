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

    test 'returns servers' do
      assert_equal(
        %w[
          http://example.com/v1
          http://staging.example.com/v1
        ],
        @specification.servers.map(&:url)
      )
    end

    test 'uses the first server URL as the default base URL' do
      assert_equal 'http://example.com/v1', @specification.default_base_url
    end

    test 'groups query params for an operation with query params' do
      operation = @specification.operation('searchBooks')
      params = { 'q' => 'Aldous Huxley' }
      assert_equal(
        { 'query' => params },
        @specification.build_grouped_params(operation.node, params)
      )
    end

    test 'groups path params for an operation with path params' do
      operation = @specification.operation('fetchBook')
      params = { 'id' => 12 }
      assert_equal(
        { 'path' => params },
        @specification.build_grouped_params(operation.node, params)
      )
    end

    test 'groups query params for an operation without params in the specification' do
      operation = @specification.operation('sampleBook')
      params = { 'q' => 'Aldous Huxley' }
      assert_equal(
        { 'query' => params },
        @specification.build_grouped_params(operation.node, params)
      )
    end

    test 'serializes body for an operation with a request body' do
      operation = @specification.operation('createBook')
      body = @specification.build_body(operation.node, {})
      assert_equal 'application/json', body.content_type
      assert_equal '{}', body.to_s
    end

    test 'serializes body with default serialization for an operation without a request body' do
      operation = @specification.operation('createBook')
      body = @specification.build_body(operation.node, {})
      assert_equal 'application/json', body.content_type
      assert_equal '{}', body.to_s
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

    test 'finds a schema relative to a media type' do
      operation = @specification.operation('listBooks')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      assert_equal(
        %w[paths /books get responses 200 content application/json schema],
        schema.node
      )
      assert_equal('array', schema.object_type)
      assert_equal('Book', schema.item_schema_name)

      operation = @specification.operation('fetchBook')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      assert_equal(
        %w[paths /books/{id} get responses 200 content application/json schema],
        schema.node
      )
      assert_equal('object', schema.object_type)
      assert_nil schema.item_schema_name
    end

    test 'uses first response when HTTP response does not have a media type' do
      operation = @specification.operation('listBooks')
      media_type = @specification.media_type(operation.node, '200', nil)
      schema = @specification.schema(media_type.node)
      assert_equal(
        %w[paths /books get responses 200 content application/json schema],
        schema.node
      )
      assert_equal('array', schema.object_type)
      assert_equal('Book', schema.item_schema_name)

      operation = @specification.operation('fetchBook')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      assert_equal(
        %w[paths /books/{id} get responses 200 content application/json schema],
        schema.node
      )
      assert_equal('object', schema.object_type)
      assert_nil schema.item_schema_name
    end
  end
end
