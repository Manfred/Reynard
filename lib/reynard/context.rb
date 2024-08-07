# frozen_string_literal: true

class Reynard
  # Exposes a public interface to build a request context.
  class Context
    extend Forwardable
    def_delegators :@request_context, :verb, :path, :full_path, :url

    def initialize(specification:, request_context: nil, response_context: nil)
      @specification = specification
      @request_context = request_context || build_request_context
      @response_context = response_context || ResponseContext.build
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
      copy(request: { body: self.class.merge_body(@request_context.body, data) })
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

    def serializer(content_type, serializer)
      copy(
        request: {
          serializers: @request_context.serializers.merge({ content_type => serializer }).compact
        }
      )
    end

    def deserializer(content_type, deserializer)
      copy(
        response: {
          deserializers: @response_context.deserializers.merge(
            { content_type => deserializer }
          ).compact
        }
      )
    end

    def property_naming(property_naming)
      copy(reponse: { property_naming: property_naming })
    end

    def model_registry(model_registry)
      copy(response: { model_registry: model_registry })
    end

    def model_naming(model_naming)
      copy(response: { model_naming: model_naming })
    end

    def execute
      build_response(build_request.perform)
    end

    def self.merge_body(current, data)
      case current
      when NilClass
        data
      when Hash
        current.merge(data)
      else
        raise(
          ArgumentError,
          "Please assign the request body once, we can't merge #{data.inspect} into " \
          "#{current.inspect}."
        )
      end
    end

    private

    def build_request_context
      RequestContext.new(
        base_url: @specification.default_base_url,
        headers: {},
        serializers: Reynard.serializers.dup
      )
    end

    def copy(request: {}, response: {})
      self.class.new(
        specification: @specification,
        request_context: @request_context.copy(**request),
        response_context: @response_context.copy(**response)
      )
    end

    def build_request
      Reynard::Http::Request.new(
        request_context: @request_context,
        serializer_selection: serializer_selection
      )
    end

    def serializer_selection
      @specification
        .content(@request_context.operation.node)
        .pick_serializer(@request_context.serializers)
    end

    def build_response(http_response)
      Reynard::Http::Response.new(
        specification: @specification,
        request_context: @request_context,
        response_context: @response_context,
        http_response: http_response
      )
    end
  end
end
