# frozen_string_literal: true

class Reynard
  # Transforms property names so they are value Ruby identifiers or more readable to users.
  class Inflector
    def initialize
      @snake_case = {}
    end

    # Registers additional exceptions to the regular snake-case algorithm. Registering is additive
    # so you can call this multiple times without losing previously registered exceptions.
    def snake_cases(exceptions)
      @snake_case.merge!(exceptions)
    end

    # Returns the string in snake-case, taking previously registered exceptions into account.
    def snake_case(property)
      @snake_case[property] || self.class.snake_case(property)
    end

    # Returns the string in snake-case.
    def self.snake_case(property)
      property
        .to_s
        .gsub(/([A-Z])(?=[A-Z][a-z])|([a-z\d])(?=[A-Z])/) { (Regexp.last_match(1) || Regexp.last_match(2)) << '_' }
        .tr("'\"-", '___')
        .downcase
    end
  end
end
