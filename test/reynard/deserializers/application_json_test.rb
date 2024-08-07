# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  module Deserializers
    class ApplicationJsonTest < Reynard::Test
      test 'parses a JSON body' do
        assert_equal(
          { 'id' => 1 },
          ApplicationJson.new(headers: {}, body: '{"id":1}').call
        )
      end
    end
  end
end
