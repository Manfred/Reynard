# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class MediaTypeTest < Reynard::Test
    def setup
      @media_type = Reynard::MediaType.new(
        node: %w[
          paths
          /books/{id}
          get
          responses
          200
          content
          application/json
        ],
        schema_name: 'Book'
      )
    end

    test 'returns media type and response code based on the media type node' do
      assert_equal 'application/json', @media_type.media_type
      assert_equal '200', @media_type.response_code
    end
  end
end
