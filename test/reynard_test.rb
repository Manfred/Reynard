# frozen_string_literal: true

require_relative 'test_helper'

class ReynardTest < Reynard::Test
  def setup
    @reynard = Reynard.new(filename: fixture_file('openapi/simple.yml'))
  end

  test 'returns all available servers' do
    servers = @reynard.servers
    assert_equal 2, servers.length
    assert_equal(
      %w[
        http://example.com/v1
        http://staging.example.com/v1
      ],
      servers.map(&:url)
    )
  end

  test 'changes the base URL' do
    base_url = 'https://example.com/v2'
    context = @reynard.base_url(base_url)
    assert_equal base_url, context.url
  end

  test 'updates the base URL by selecting a server' do
    base_url = @reynard.servers.map(&:url).find do |url|
      /staging/.match(url)
    end
    context = @reynard.base_url(base_url)
    assert_equal 'http://staging.example.com/v1', context.url
  end

  test 'updates a context with an operation name' do
    context = @reynard.operation('listBooks')
    assert_equal '/books', context.path
  end

  test 'updates a context with params' do
    context = @reynard.operation('listBooks').params(id: 42, order: 'desc')
    assert_equal 'http://example.com/v1/books?id=42&order=desc', context.url
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
