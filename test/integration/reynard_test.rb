# frozen_string_literal: true

require_relative '../test_helper'

require 'open3'

module Integration
  class ReynardTest < Reynard::Test
    def setup
      WebMock.disable_net_connect!(allow_localhost: true)

      @reynard = Reynard.new(
        filename: fixture_file('openapi/simple.yml')
      ).base_url(
        "http://127.0.0.1:#{SimpleService.options.port}"
      )
    end

    def teardown
      super
      WebMock.disable_net_connect!
    end

    test 'fetches a collection' do
      with_simple_service do
        response = @reynard.operation('listBooks').execute
        assert_equal '200', response.code
        books = response.object
        assert_kind_of Reynard::Models::BooksCollection, books
      end
    end

    test 'fetches an object' do
      with_simple_service do
        response = @reynard.operation('fetchBook').params(id: 1).execute
        assert_equal '200', response.code
        book = response.object
        assert_kind_of Reynard::Models::Book, book
      end
    end

    test 'creates an object' do
      with_simple_service do
        name = 'An unexpected occurance'
        response = @reynard.operation('createBook').body({ 'name' => name }).execute
        assert_equal '200', response.code
        book = response.object
        assert_kind_of Reynard::Models::Book, book
        assert_equal name, book.name
      end
    end

    test 'returns an error when fetching an object fails' do
      with_simple_service do
        response = @reynard.operation('fetchBook').params(id: -1).execute
        assert_equal '404', response.code
        error = response.object
        assert_kind_of Reynard::Models::Error, error
        assert_equal 'not_found', error.error
      end
    end

    test 'performs threaded requests' do
      with_simple_service do
        threads = []
        3.times do
          threads << Thread.new do
            response = @reynard.operation('fetchBook').params(id: 1).execute
            assert_equal 1, response.object.id
          end
        end
        threads.map(&:join)
      end
    end

    private

    def with_simple_service
      Open3.popen2e(
        'ruby', "#{SUPPORT_ROOT}/simple_service.rb"
      ) do |stdin, output, thread|
        stdin.close
        wait_until(output, URI(@reynard.url))
        yield
      ensure
        Process.kill('TERM', thread.pid)
      end
    end

    def wait_until(_output, uri)
      # Wait for the server to respond to the URI.
      120.times do
        Net::HTTP.get_response(uri)
      rescue Errno::ECONNREFUSED
        sleep 0.5
      else
        break
      end
    end
  end
end
