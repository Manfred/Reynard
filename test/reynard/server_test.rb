# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ServerTest < Reynard::Test
    test 'initializes with attributes' do
      server = Server.new('url' => 'http://example.com')
      assert_equal 'http://example.com', server.url
    end
  end
end
