# frozen_string_literal: true

class Reynard
  # Basic implementation of URI templates.
  #
  # See: RFC6570
  class Template
    VARIABLE_RE = /\{([^}]+)\}/.freeze

    def initialize(template, params)
      @template = template
      @params = params
    end

    def result
      @template.gsub(VARIABLE_RE) do
        Rack::Utils.escape_path(@params.fetch(Regexp.last_match(1)).to_s)
      end
    end
  end
end
