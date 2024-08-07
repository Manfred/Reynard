# frozen_string_literal: true

class Reynard
  class Collection < ::Array
    class << self
      # Allows Reynard to name a collection when it's not defined as a constant.
      attr_accessor :name

      # Contains the module or class namespace when built in relation to another model. For
      # example: "Library::Author".
      attr_accessor :namespace
    end
  end
end
