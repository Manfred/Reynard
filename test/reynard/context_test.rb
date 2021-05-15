# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ContextTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
    end

    test 'does not have a query without params' do
      refute(
        Reynard::Context.new(
          specification: @specification,
          operation: @specification.operation('searchBooks'),
          params: nil
        ).query?
      )
    end

    test 'does not have a query when params are empty' do
      refute(
        Reynard::Context.new(
          specification: @specification,
          operation: @specification.operation('searchBooks'),
          params: {}
        ).query?
      )
    end

    test 'does not have a query when params are not query params' do
      refute(
        Reynard::Context.new(
          specification: @specification,
          operation: @specification.operation('searchBooks'),
          params: { name: 'Sama' }
        ).query?
      )
    end

    test 'has a query when there are query params' do
      assert(
        Reynard::Context.new(
          specification: @specification,
          operation: @specification.operation('searchBooks'),
          params: { q: 'Sama' }
        ).query?
      )
    end

    test 'does not return a query when there are no params' do
      assert_nil(
        Reynard::Context.new(
          specification: @specification,
          operation: @specification.operation('searchBooks'),
          params: nil
        ).query
      )
    end

    test 'builds a safe query when there are params' do
      assert_equal(
        'q=%E2%9A%A1%EF%B8%8F',
        Reynard::Context.new(
          specification: @specification,
          operation: @specification.operation('searchBooks'),
          params: { q: '⚡️' }
        ).query
      )
    end

    test 'builds urls with parameter in path' do
      context = Reynard::Context.new(
        specification: @specification,
        operation: @specification.operation('fetchBook'),
        params: { id: 42 }
      )
      urls = []
      context.each_url { |url| urls << url }
      assert_equal %w[http://example.com/v1/books/42], urls
    end

    test 'builds urls with parameter in query' do
      context = Reynard::Context.new(
        specification: @specification,
        operation: @specification.operation('searchBooks'),
        params: { q: '"Lucene Sky"' }
      )
      urls = []
      context.each_url { |url| urls << url }
      assert_equal %w[http://example.com/v1/search/books?q=%22Lucene+Sky%22], urls
    end
  end
end
