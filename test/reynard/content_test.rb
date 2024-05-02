# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ContentTest < Reynard::Test
    def setup
      @content = Content.new(
        keys: %w[application/json text/plain]
      )
    end

    test 'picks serializer for the first matching content-type defined in the specification' do
      serializer = @content.pick_serializer({ 'application/json' => Mocks::Serializer })
      assert_equal('application/json', serializer.content_type)
      assert_equal(Mocks::Serializer, serializer.serializer_class)

      serializer = @content.pick_serializer({ 'text/plain' => Mocks::Serializer })
      assert_equal('text/plain', serializer.content_type)
      assert_equal(Mocks::Serializer, serializer.serializer_class)

      serializer = @content.pick_serializer(
        {
          'text/plain' => false,
          'application/json' => Mocks::Serializer
        }
      )
      assert_equal('application/json', serializer.content_type)
      assert_equal(Mocks::Serializer, serializer.serializer_class)
    end

    test 'does not pick a serializer when there is no matching content-type' do
      assert_nil @content.pick_serializer({ 'image/jpeg' => true })
    end

    test 'does not pick a serializer when there are no serializers' do
      assert_nil @content.pick_serializer(nil)
    end
  end

  class ContentWithoutContentTypesTest < Reynard::Test
    def setup
      @content = Content.new(
        keys: []
      )
    end

    test 'does not pick a serializer when there is no matching content-type' do
      assert_nil @content.pick_serializer({ 'image/jpeg' => true })
    end

    test 'does not pick a serializer when there are no serializers' do
      assert_nil @content.pick_serializer(nil)
    end
  end
end
