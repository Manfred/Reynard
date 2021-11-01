# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  class Http
    # Requests are tested through Context because replicating a RequestContext without a full
    # specification is kind of cumbersome.
    class RequestTest < Reynard::Test
    end
  end
end
