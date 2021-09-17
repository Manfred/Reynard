# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class SerializedBodyTest < Reynard::Test
    def setup
      @name = 'White Mirror'
      @serialized_body = SerializedBody.new(
        { 'application/json' => { 'schema' => { '$ref' => '#/components/schemas/Book' } } },
        { 'name' => @name }
      )
    end

    test 'returns the content-type' do
      assert_equal 'application/json', @serialized_body.content_type
    end

    test 'returns request headers' do
      assert_equal({ 'Content-Type' => 'application/json' }, @serialized_body.headers)
    end

    test 'serializes data to JSON' do
      assert_equal('{"name":"White Mirror"}', @serialized_body.to_s)
    end
  end
end
