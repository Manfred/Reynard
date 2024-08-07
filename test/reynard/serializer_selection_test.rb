# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class SerializerSelectionTest < Reynard::Test
    def setup
      @content_type = 'application/json'
      @serializer_class = Mocks::Serializer
      @serializer = SerializerSelection.new(
        content_type: @content_type,
        serializer_class: @serializer_class
      )
      @data = { 'name' => name }
    end

    test 'returns the used content-type' do
      assert_equal @content_type, @serializer.content_type
    end

    test 'returns the selected serializer class' do
      assert_equal @serializer_class, @serializer.serializer_class
    end
  end
end
