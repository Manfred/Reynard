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

    test 'finds each node with a specified type in the specification' do
      found = false
      @specification.find_each(type: 'object') do |node|
        found = true
        assert_equal('object', @specification.dig(*node)['type'])
      end
      assert found
    end

    test 'does not find nodes with non-existent type' do
      @specification.find_each(type: 'non-existent') do
        raise 'Must not find anything'
      end
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

      operation = @specification.operation('searchBooks')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      assert_equal(
        %w[paths /search/books get responses 200 content application/json],
        media_type.node
      )
    end

    test 'finds the default media type for unknown response code' do
      operation = @specification.operation('listBooks')
      media_type = @specification.media_type(operation.node, '100', 'application/json')
      assert_equal(
        %w[paths /books get responses default content application/json],
        media_type.node
      )
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
      assert_equal('array', schema.type)
      assert_equal('Books', schema.model_name)
      assert_equal('Book', schema.item_schema.model_name)

      operation = @specification.operation('fetchBook')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      assert_equal(
        %w[paths /books/{id} get responses 200 content application/json schema],
        schema.node
      )
      assert_equal('object', schema.type)
      assert_equal('Book', schema.model_name)
      assert_nil schema.item_schema
    end

    test 'uses first response when HTTP response does not have a media type' do
      operation = @specification.operation('listBooks')
      media_type = @specification.media_type(operation.node, '200', nil)
      schema = @specification.schema(media_type.node)
      assert_equal(
        %w[paths /books get responses 200 content application/json schema],
        schema.node
      )
      assert_equal('array', schema.type)
      assert_equal('Books', schema.model_name)
      assert_equal('Book', schema.item_schema.model_name)

      operation = @specification.operation('fetchBook')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      assert_equal(
        %w[paths /books/{id} get responses 200 content application/json schema],
        schema.node
      )
      assert_equal('object', schema.type)
      assert_equal('Book', schema.model_name)
      assert_nil schema.item_schema
    end
  end

  class ParametersSpecificationTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/params.yml'))
    end

    test 'applies a parameter specification at the path level' do
      operation = @specification.operation('getSpace')
      params = { 'name' => 'yellow', 'filter' => 'rgb' }
      assert_equal(
        { 'path' => { 'name' => 'yellow' }, 'query' => { 'filter' => 'rgb' } },
        @specification.build_grouped_params(operation.node, params)
      )
    end

    test 'applies a parameter specification at the path level overriden at operation level' do
      operation = @specification.operation('updateSpace')
      params = { 'name' => 'yellow', 'filter' => 'rgb' }
      assert_equal(
        { 'path' => { 'name' => 'yellow' }, 'query' => { 'filter' => 'rgb' } },
        @specification.build_grouped_params(operation.node, params)
      )
    end
  end

  class BareSpecificationTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/bare.yml'))
    end

    test 'does not return a media type when the returned response code is not described' do
      operation = @specification.operation('listClowns')
      assert_nil @specification.media_type(operation.node, '500', nil)
    end
  end

  class ExernalSpecificationTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/external.yml'))
    end

    test 'digs into an external file' do
      data = @specification.dig(
        'paths', '/authors/{id}', 'get', 'responses', '200',
        'content', 'application/json', 'schema'
      )
      assert_equal 'Author', data['title']
    end

    test 'digs into an external file through a reference' do
      data = @specification.dig(
        'paths', '/authors/{id}', 'get', 'responses', '200',
        'content', 'application/json', 'schema',
        'properties', 'id', 'type'
      )
      assert_equal 'integer', data
    end

    test 'digs into an external file through a reference in an external file' do
      data = @specification.dig(
        'paths', '/authors/{id}', 'get', 'responses', '200',
        'content', 'application/json', 'schema',
        'properties', 'bio', 'properties', 'age', 'type'
      )
      assert_equal 'integer', data
    end

    test 'digs into an external file with an anchor' do
      data = @specification.dig(
        'paths', '/authors/{id}', 'get', 'responses', 'default',
        'content', 'application/json', 'schema'
      )
      assert_equal %w[code message], data['required']
    end

    test 'digs into an external file through a reference with with an anchor' do
      data = @specification.dig(
        'paths', '/authors/{id}', 'get', 'responses', 'default',
        'content', 'application/json', 'schema', 'required'
      )
      assert_equal %w[code message], data
    end
  end
end
