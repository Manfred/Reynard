# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class SpecificationTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
    end

    test 'initializes with an OpenAPI filename' do
      assert_equal 'Library', @specification.dig('info', 'title')
    end

    test 'digs into the specification through references' do
      assert_equal(
        %w[id name],
        @specification.dig('components', 'schemas', 'Books', 'items', 'required')
      )
    end
  end
end
