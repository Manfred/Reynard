# frozen_string_literal: true

require_relative '../../test_helper'
require 'tempfile'

class Reynard
  module Serializers
    class TextPlainTest < Reynard::Test
      test 'returns a mime-type' do
        assert_equal 'text/plain', TextPlain.new(data: nil).mime_type
      end

      test 'returns request headers' do
        text_plain = TextPlain.new(data: nil)
        assert_equal(
          { 'Content-Type' => text_plain.mime_type.to_s },
          text_plain.headers
        )
      end

      test 'writes the data directly to the request body' do
        text_plain = TextPlain.new(data: 'data')
        assert_equal('data', text_plain.body)
      end
    end
  end
end
