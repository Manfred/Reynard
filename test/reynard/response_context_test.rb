# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ResponseContextTest < Reynard::Test
    def setup
      @response_context = Reynard::ResponseContext.new
      @logger = Logger.new('/dev/null')
    end

    test 'does not return a logger when it is not set' do
      assert_nil @response_context.logger
    end

    test 'does not have any serializers when none are set' do
      assert_nil @response_context.deserializers
    end

    test 'can replace all properties when copying' do
      properties = {
        logger: @logger,
        deserializers: Reynard.deserializers.dup,
        model_registry: Reynard::Naming::ModelRegistry.new,
        model_naming: Reynard::Naming::ModelNaming
      }
      copy = @response_context.copy(**properties)
      properties.each do |name, value|
        assert_equal value, copy.send(name)
      end
    end
  end
end
