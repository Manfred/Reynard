# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class OperationTest < Reynard::Test
    def setup
      @operation = Operation.new(node: %w[paths /books get])
    end

    test 'returns the request path' do
      assert_equal '/books', @operation.path
    end

    test 'returns the request verb' do
      assert_equal 'get', @operation.verb
    end
  end
end
