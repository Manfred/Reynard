# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  module Serializers
    class ApplicationJsonTest < Reynard::Test
      test 'returns a mime-type' do
        assert_equal 'application/json', ApplicationJson.new(data: nil).mime_type
      end

      test 'returns request headers' do
        application_json = ApplicationJson.new(data: nil)
        assert_equal(
          { 'Content-Type' => application_json.mime_type.to_s },
          application_json.headers
        )
      end

      test 'serializes data to the request body' do
        application_json = ApplicationJson.new(
          data: {
            'id' => 12,
            'name' => 'Print & Copy',
            '("real")' => 'quote'
          }
        )
        assert_equal(
          '{"id":12,"name":"Print & Copy","(\"real\")":"quote"}',
          application_json.body
        )
      end
    end
  end
end
