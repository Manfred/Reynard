# frozen_string_literal: true

module Assertions
  def assert_model_name(class_name, object)
    assert_equal("Reynard::Models::#{class_name}", object.class.name)
  end
end
