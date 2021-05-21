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

  test 'performs a request that returns an object' do
    @book = { id: 42, name: 'Black Science' }
    context = Reynard
              .new(filename: fixture_file('openapi/simple.yml'))
              .operation('fetchBook')
              .params(id: 42)
    stub_request(:get, "http://example.com/v1#{context.full_path}")
      .to_return(
        body: MultiJson.dump(@book),
        headers: {
          'Content-Type' => 'application/json; charset=utf-8'
        }
      )
    record = context.execute
    @book.each do |name, value|
      assert_equal value, record.send(name)
    end
  end
end
