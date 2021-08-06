# frozen_string_literal: true

class Reynard
  # Exposes a public interface to build a request context.
  class Context
    extend Forwardable
    def_delegators :@request_context, :verb, :path, :full_path, :url

    def initialize(specification:, request_context: nil)
      @specification = specification
      @request_context = request_context || build_request_context
    end

    def base_url(base_url)
      copy(base_url: base_url)
    end

    def operation(operation_name)
      copy(operation: @specification.operation(operation_name))
    end

    def params(params)
      params = params.transform_keys(&:to_s)
      copy(params: @specification.build_grouped_params(@request_context.operation.node, params))
    end

    def headers(headers)
      copy(headers: headers)
    end

    def execute
      build_object(build_request.perform)
    end

    private

    def build_request_context
      RequestContext.new(base_url: @specification.default_base_url)
    end

    def copy(**properties)
      self.class.new(
        specification: @specification,
        request_context: @request_context.copy(**properties)
      )
    end

    def build_request
      Reynard::Http::Request.new(request_context: @request_context)
    end

    def build_object(http_response)
      media_type = @specification.media_type(
        @request_context.operation.node,
        http_response.code,
        http_response.content_type
      )
      ObjectBuilder.new(
        media_type: media_type,
        schema: @specification.schema(media_type.node),
        http_response: http_response
      ).call
    end
  end
end
