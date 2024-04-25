# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ContextTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
      @request_context = RequestContext.new(base_url: @specification.default_base_url, headers: {})
      @inflector = Inflector.new
      @context = Context.new(
        specification: @specification, inflector: @inflector, request_context: @request_context
      )
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

    test 'executes a request for a collection' do
      stub_request(:get, 'http://example.com/v1/books').and_return(
        body: '[{"id":1},{"id":2},{"id":3}]'
      )
      response = @context.operation('listBooks').execute
      assert_equal '200', response.code
      assert_equal [1, 2, 3], response.object.map(&:id)
    end

    test 'executes a request for a single resource' do
      stub_request(:get, 'http://example.com/v1/books/1').and_return(body: '{"id":1}')
      response = @context.operation('fetchBook').params(id: 1).execute
      assert_equal '200', response.code
      assert_equal 1, response.object.id
    end

    test 'executes a request for a single resource with a specific content-type' do
      stub_request(:get, 'http://example.com/v1/books/1').and_return(body: '{"id":1}')
      response = @context
                 .operation('fetchBook')
                 .headers('Accept' => 'application/json')
                 .params(id: 1)
                 .execute
      assert_equal '200', response.code
      assert_equal 1, response.object.id
    end

    test 'executes a POST request with a body' do
      stub_request(:post, 'http://example.com/v1/books').and_return(body: '{"id":1,"name":"Howdy"}')
      response = @context.operation('createBook').body(name: 'Howdy').execute
      assert_equal '200', response.code
      assert_equal 1, response.object.id
      assert_equal 'Howdy', response.object.name
    end

    test 'executes a POST request without a body' do
      stub_request(:post, 'http://example.com/v1/books').and_return(body: '{"id":1,"name":"Howdy"}')
      response = @context.operation('createBook').execute
      assert_equal '200', response.code
      assert_equal 1, response.object.id
      assert_equal 'Howdy', response.object.name
    end

    test 'executes a POST request with a multipart form' do
      stub_request(:post, 'http://example.com/v1/books/covers').and_return(body: '{"id":1,"name":"Howdy"}')
      response = @context
                 .operation('createBookCover')
                 .multipart_form(name: 'Howdy')
                 .execute
      assert_equal '200', response.code
      assert_equal 1, response.object.id
      assert_equal 'Howdy', response.object.name
    end

    test 'executes a PUT request with a body' do
      stub_request(:put, 'http://example.com/v1/books/56').and_return(body: '{"id":1,"name":"Howdy"}')
      response = @context.operation('updateBook').params(id: 56).body(name: 'Howdy').execute
      assert_equal '200', response.code
      assert_equal 1, response.object.id
      assert_equal 'Howdy', response.object.name
    end

    test 'executes a PUT request without a body' do
      stub_request(:put, 'http://example.com/v1/books/83').and_return(body: '{"id":1,"name":"Howdy"}')
      response = @context.operation('updateBook').params(id: 83).execute
      assert_equal '200', response.code
      assert_equal 1, response.object.id
      assert_equal 'Howdy', response.object.name
    end

    test 'executes a PATCH request with a body' do
      stub_request(:patch, 'http://example.com/v1/books/12').and_return(body: '{"id":1,"name":"Howdy"}')
      response = @context.operation('updateBook2').params(id: 12).body(name: 'Howdy').execute
      assert_equal '200', response.code
      assert_equal 1, response.object.id
      assert_equal 'Howdy', response.object.name
    end

    test 'executes a PATCH request without a body' do
      stub_request(:patch, 'http://example.com/v1/books/93').and_return(body: '{"id":1,"name":"Howdy"}')
      response = @context.operation('updateBook2').params(id: 93).execute
      assert_equal '200', response.code
      assert_equal 1, response.object.id
      assert_equal 'Howdy', response.object.name
    end

    test 'executes a DELETE request with a body' do
      stub_request(:delete, 'http://example.com/v1/books/29').and_return(status: 204)
      response = @context.operation('deleteBook').params(id: 29).execute
      assert_equal '204', response.code
      assert_nil response.object
    end

    test 'logs request details when a logger at debug level is assigned' do
      out = StringIO.new
      logger = ::Logger.new(out)
      logger.level = ::Logger::DEBUG
      stub_request(:post, 'http://example.com/v1/books').and_return(body: '{"id":1,"name":"Howdy"}')
      @context.logger(logger).operation('createBook').body({}).execute
      lines = out.string.split("\n")
      assert_equal 2, lines.length
      assert lines[0].end_with?('INFO -- : POST http://example.com/v1/books')
      assert lines[1].end_with?('DEBUG -- : {}')
    end

    test 'logs request details when a logger at info level is assigned' do
      out = StringIO.new
      logger = ::Logger.new(out)
      logger.level = ::Logger::INFO
      stub_request(:post, 'http://example.com/v1/books').and_return(body: '{"id":1,"name":"Howdy"}')
      @context.logger(logger).operation('createBook').body({}).execute
      lines = out.string.split("\n")
      assert_equal 1, lines.length
      assert lines[0].end_with?('INFO -- : POST http://example.com/v1/books')
    end

    test 'includes the User-Agent with a request' do
      stub_request(:get, 'http://example.com/v1/books').with(
        headers: { 'User-Agent' => Reynard.user_agent.to_s }
      ).and_return(
        body: '[{"id":1},{"id":2},{"id":3}]'
      )
      response = @context.operation('listBooks').execute
      assert_equal '200', response.code
      assert_equal [1, 2, 3], response.object.map(&:id)
    end

    test 'allows customization of the User-Agent' do
      user_agent = 'Weeeeeeeeeeeeee/1.1'
      stub_request(:get, 'http://example.com/v1/books').with(
        headers: { 'User-Agent' => user_agent }
      ).and_return(
        body: '[{"id":1},{"id":2},{"id":3}]'
      )
      response = @context.headers({ 'User-Agent' => user_agent }).operation('listBooks').execute
      assert_equal '200', response.code
      assert_equal [1, 2, 3], response.object.map(&:id)
    end
  end

  class BareContextTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/bare.yml'))
      @request_context = RequestContext.new(base_url: @specification.default_base_url, headers: {})
      @inflector = Inflector.new
      @context = Context.new(
        specification: @specification, inflector: @inflector, request_context: @request_context
      )
    end

    test 'returns a generic result when response is not defined' do
      stub_request(:get, 'http://example.com/clowns').and_return(
        status: 500, body: '{"message":"Howdy"}'
      )
      response = @context.operation('listClowns').execute
      assert_kind_of Reynard::Model, response.object
      assert_equal 'Howdy', response.object.message
    end
  end

  class InflectorContextTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/nested.yml'))
      @request_context = RequestContext.new(base_url: @specification.default_base_url, headers: {})
      @inflector = Inflector.new
      @inflector.snake_cases({ '1st-class' => 'first_class' })
      @context = Context.new(
        specification: @specification, inflector: @inflector, request_context: @request_context
      )
    end

    test 'allows access to irregular properties through snake case methods' do
      stub_request(:get, 'http://example.com/v1/library').and_return(
        status: 200, body: JSON.dump(
          {
            'name' => '1st Library',
            'books' => [
              {
                'name' => 'Erebus', 'author' => {
                  'name' => 'Palin', 'streetName' => 'Townstreet', '1st-class' => 'false'
                }
              }
            ]
          }
        )
      )
      response = @context.operation('showLibrary').execute
      assert_kind_of Reynard::Model, response.object
      author = response.object.books[0].author
      assert_equal 'Palin', author.name
      assert_equal 'Townstreet', author.street_name
      assert_equal 'Townstreet', author.streetName
      assert_equal 'false', author.first_class
      assert_equal 'false', author['1st-class']
    end
  end
end
