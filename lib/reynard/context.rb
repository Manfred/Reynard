# frozen_string_literal: true

require 'ostruct'

class Reynard
  # Exposes a public interface to build a request context.
  class Context
    extend Forwardable
    def_delegators :@request_context, :verb, :path, :full_path, :url

    def initialize(specification:, inflector:, request_context: nil, response_context: nil)
      @specification = specification
      @inflector = inflector
      @request_context = request_context || build_request_context
      @response_context = response_context || build_response_context
    end

    def base_url(base_url)
      copy(request: { base_url: base_url })
    end

    def operation(operation_name)
      copy(request: { operation: @specification.operation(operation_name) })
    end

    def params(params)
      params = params.transform_keys(&:to_s)
      copy(
        request: {
          params: @specification.build_grouped_params(@request_context.operation.node, params)
        }
      )
    end

    def body(data)
      return unless @request_context.operation

      serialized_body = @specification.build_body(@request_context.operation.node, data)
      return unless serialized_body

      copy(
        request: {
          headers: @request_context.headers.merge(serialized_body.headers),
          body: serialized_body.to_s
        }
      )
    end

    def headers(headers)
      copy(request: { headers: @request_context.headers.merge(headers) })
    end

    def logger(logger)
      copy(
        request: { logger: logger },
        response: { logger: logger }
      )
    end

    def execute
      build_response(build_request.perform)
    end

    private

    def build_request_context
      RequestContext.new(base_url: @specification.default_base_url, headers: {})
    end

    def build_response_context
      ResponseContext.new
    end

    def copy(request: {}, response: {})
      self.class.new(
        specification: @specification,
        inflector: @inflector,
        request_context: @request_context.copy(**request),
        response_context: @request_context.copy(**response)
      )
    end

    def build_request
      Reynard::Http::Request.new(request_context: @request_context)
    end

    def build_response(http_response)
      Reynard::Http::Response.new(
        specification: @specification,
        inflector: @inflector,
        request_context: @request_context,
        http_response: http_response
      )
    end
  end
end
