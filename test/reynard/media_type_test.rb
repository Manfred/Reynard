# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class MediaTypeTest < Reynard::Test
    def setup
      @node = %w[
        paths
        /books/{id}
        get
        responses
        200
        content
        application/json
      ]
      @media_type = Reynard::MediaType.new(node: @node)
    end

    test 'returns its own node' do
      assert_equal @node, @media_type.node
    end
  end
end
