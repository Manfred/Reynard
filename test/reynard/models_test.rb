# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ModelsTest < Reynard::Test
    test 'exists' do
      assert_kind_of Module, Reynard::Models
    end
  end
end
