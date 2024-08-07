# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  class Specification
    class QueryTest < Reynard::Test
      test 'represents a query for a type node in a specification' do
        query = Query.new(type: 'object')
        assert_equal 'object', query.type
      end
    end
  end
end
