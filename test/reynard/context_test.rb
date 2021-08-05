# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ContextTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
      @request_context = RequestContext.new(base_url: @specification.default_base_url)
      @context = Context.new(specification: @specification, request_context: @request_context)
    end

    test 'does not have a verb without an operation' do
      assert_nil @context.verb
    end

    test 'returns the verb for the operation' do
      assert_equal 'get', @context.operation('searchBooks').verb
    end

    test 'does not have a path without an operation' do
      assert_nil @context.path
    end

    test 'returns the path for the operation' do
      assert_equal '/search/books', @context.operation('searchBooks').path
    end

    test 'does not have a full path without an operation' do
      assert_nil @context.full_path
    end

    test 'returns the full path for the operation' do
      assert_equal '/search/books', @context.operation('searchBooks').full_path
    end

    test 'returns its first server URL as its base URL by default' do
      assert_equal('http://example.com/v1', @context.url)
    end

    test 'returns a specific URL as its base URL' do
      base_url = 'http://test.example.com/v1'
      assert_equal(base_url, @context.base_url(base_url).url)
    end

    test 'does not include query in the URL when no operation is selected' do
      assert_nil URI(@context.url).query
    end

    test 'does not return a query when there are no params' do
      assert_nil URI(@context.operation('searchBooks').url).query
    end

    test 'builds a safe query when there are params' do
      assert_equal(
        'http://example.com/v1/search/books?q=%E2%9A%A1%EF%B8%8F',
        @context.operation('searchBooks').params(q: '⚡️').url
      )
      assert_equal(
        'http://example.com/v1/search/books?q=%22Lucene+Sky%22',
        @context.operation('searchBooks').params(q: '"Lucene Sky"').url
      )
    end

    test 'builds url with parameter in path' do
      assert_equal(
        'http://example.com/v1/books/42',
        @context.operation('fetchBook').params(id: 42).url
      )
    end
  end
end
