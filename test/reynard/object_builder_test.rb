# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ObjectBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
    end

    test 'build a singular record' do
      operation = @specification.operation('fetchBook')
      media_type = @specification.media_type(operation.node, '200', 'application/json')
      schema = @specification.schema(media_type.node)
      record = Reynard::ObjectBuilder.new(
        media_type: media_type,
        schema: schema,
        http_response: OpenStruct.new(body: '{"id":42,"name":"Black Science"}')
      ).call
      assert_kind_of(
        Reynard::ObjectBuilder.model_class('Book'),
        record
      )
      assert_equal 42, record.id
      assert_equal 'Black Science', record.name
    end
  end
end
