# frozen_string_literal: true

class Reynard
  # Contains classes that wrap Net::HTTP to provide a slightly more convenient interface.
  class Http
    autoload :Request, 'reynard/http/request'
    autoload :Response, 'reynard/http/response'
  end
end
