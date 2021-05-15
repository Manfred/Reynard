# frozen_string_literal: true

require_relative 'test_helper'

class ReynardTest < Reynard::Test
  def setup
    @reynard = Reynard.new(filename: fixture_file('openapi/simple.yml'))
  end

  test 'starts a context with an operation name' do
    context = @reynard.operation('listBooks')
    assert_equal '/books', context.path
  end

  test 'starts a context with params' do
    context = @reynard.operation('listBooks').params(id: 42, order: 'desc')
    assert_equal 'order=desc', context.query
  end

  test 'performs a request' do
    @books = [
      { id: 42, name: 'Black Science' },
      { id: 43, name: 'American Gods' }
    ]
    context = Reynard
              .new(filename: fixture_file('openapi/simple.yml'))
              .operation('searchBooks')
              .params(q: '🎉')
    stub_request(:get, "http://example.com/v1#{context.full_path}")
      .to_return(
        body: MultiJson.dump(@books),
        headers: {
          'Content-Type' => 'application/json; charset=utf-8'
        }
      )
    result = context.execute
    assert_equal('200', result.code)
    assert_equal(
      @books.map { |object| object.transform_keys(&:to_s) },
      MultiJson.load(result.body)
    )
  end
end
