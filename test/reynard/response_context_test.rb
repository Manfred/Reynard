# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ResponseContextTest < Reynard::Test
    def setup
      @response_context = Reynard::ResponseContext.new
    end

    test 'does not return a logger when it is not set' do
      assert_nil @response_context.logger
    end
  end
end
