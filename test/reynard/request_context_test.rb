# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class RequestContextTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
      @request_context = Reynard::RequestContext.new
    end

    test 'does not return a verb when no operation is selected' do
      assert_nil @request_context.verb
    end

    test 'returns the verb when an operation is selected' do
      @request_context.operation = @specification.operation('listBooks')
      assert_equal 'get', @request_context.verb
    end

    test 'does not return a query when no query params are set' do
      assert_nil @request_context.query
    end

    test 'returns a URL safe query when query params are set' do
      @request_context.params = { 'query' => { 'title' => '🧘', 'count' => 12 } }
      assert_equal 'title=%F0%9F%A7%98&count=12', @request_context.query
    end

    test 'does not return a request path when no operation is selected' do
      assert_nil @request_context.path
    end

    test 'returns the request path associated with the selected operation' do
      @request_context.operation = @specification.operation('searchBooks')
      assert_equal '/search/books', @request_context.path
    end

    test 'completes path parameters in the request path associated with the operation' do
      @request_context.operation = @specification.operation('fetchBook')
      @request_context.params = { 'path' => { 'id' => 72 } }
      assert_equal '/books/72', @request_context.path
    end

    test 'raises an exception when not all variables in the URI template are defined' do
      @request_context.operation = @specification.operation('fetchBook')
      assert_raises(KeyError) { @request_context.path }
    end

    test 'does not return a full path when no operation is selected' do
      assert_nil @request_context.full_path
    end

    test 'returns the full path associated with the selected operation' do
      @request_context.operation = @specification.operation('searchBooks')
      assert_equal '/search/books', @request_context.full_path
    end

    test 'return a full path with query when operation is selected and params are set' do
      @request_context.operation = @specification.operation('listBooks')
      @request_context.params = { 'query' => { 'order' => 'desc' } }
      assert_equal '/books?order=desc', @request_context.full_path
    end

    test 'does not return a url when base URL is not set and no operation is selected' do
      assert_nil @request_context.url
    end

    test 'returns the base URL when no operation is selected' do
      @request_context.base_url = 'http://example.com'
      assert_equal @request_context.base_url, @request_context.url
    end

    test 'returns the url associated with the selected operation' do
      @request_context.base_url = 'http://example.com'
      @request_context.operation = @specification.operation('searchBooks')
      assert_equal 'http://example.com/search/books', @request_context.url
    end

    test 'return a url when base URL is set, operation is selected, and params are set' do
      @request_context.base_url = 'http://example.com'
      @request_context.operation = @specification.operation('fetchBook')
      @request_context.params = { 'path' => { 'id' => 93 } }
      assert_equal 'http://example.com/books/93', @request_context.url
    end

    test 'raises an exception when attempting to interpolate a request path without params' do
      @request_context.base_url = 'http://example.com'
      @request_context.operation = @specification.operation('fetchBook')
      assert_raises(KeyError) { @request_context.url }
    end

    test 'copies a blank request context' do
      assert_equal @request_context, @request_context.copy
      refute_equal @request_context.object_id, @request_context.copy.object_id
    end

    test 'can replace all properties when copying' do
      properties = {
        base_url: 'https://example.com/v3',
        operation: @specification.operation('fetchBook'),
        headers: { 'Accept' => 'application/json' },
        params: { 'path' => { 'id' => 12 }, 'query' => { 'format' => 'csv' } }
      }
      copy = @request_context.copy(**properties)
      properties.each do |name, value|
        assert_equal value, copy.send(name)
      end
    end
  end
end
