# frozen_string_literal: true

class Reynard
  # Contains classes that wrap Net::HTTP to provide a slightly more convenient interface.
  class Http
    autoload :ConditionalRequest, 'reynard/http/conditional_request'
    autoload :ConditionalResponse, 'reynard/http/conditional_response'
    autoload :Request, 'reynard/http/request'
    autoload :Response, 'reynard/http/response'
  end
end
