# frozen_string_literal: true

class Reynard
  # Builds and keeps context for a single request to an endpoint.
  class Context
    def initialize(specification:, base_url: nil, operation: nil, params: nil)
      @specification = specification
      @base_url = base_url || find_base_url
      @operation = operation
      @params = params ? params.transform_keys(&:to_s) : nil
    end

    def query?
      grouped_params&.key?('query')
    end

    def query
      Rack::Utils.build_query(grouped_params['query']) if query?
    end

    def path
      return unless @operation

      grouped_params.fetch('path', {}).inject(@operation.path.dup) do |path, (name, value)|
        path.gsub("{#{name}}", value.to_s)
      end
    end

    def full_path
      query? ? "#{path}?#{query}" : path
    end

    def url
      "#{@base_url}#{full_path}"
    end

    def base_url(base_url)
      self.class.new(
        specification: @specification,
        base_url: base_url,
        operation: @operation,
        params: @params
      )
    end

    def operation(operation_name)
      self.class.new(
        specification: @specification,
        base_url: @base_url,
        operation: @specification.operation(operation_name),
        params: @params
      )
    end

    def params(**params)
      self.class.new(
        specification: @specification,
        base_url: @base_url,
        operation: @operation,
        params: @params ? @params.merge(params) : params
      )
    end

    def execute
      http_response = perform_request(url)
      media_type = @specification.media_type(
        @operation.node,
        http_response.code,
        http_response['Content-Type'].split(';').first
      )
      schema = @specification.schema(media_type.node)
      ObjectBuilder.new(
        media_type: media_type,
        schema: schema,
        http_response: http_response
      ).call
    end

    private

    def find_base_url
      @specification.servers.first&.url
    end

    def grouped_params
      @grouped_params ||= @params ? build_grouped_params : {}
    end

    def build_grouped_params
      @specification.dig(
        *@operation.node, 'parameters'
      ).each_with_object({}) do |attributes, grouped|
        name = attributes['name']
        next unless @params.key?(name)

        group_name = attributes.fetch('in', '_')
        grouped[group_name] ||= {}
        grouped[group_name][name] = @params[name]
      end
    end

    def perform_request(url)
      build_request(url).perform
    end

    def build_request(url)
      Reynard::Http::Request.new(@operation.verb, url: url)
    end
  end
end
