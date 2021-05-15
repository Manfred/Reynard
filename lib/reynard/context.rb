# frozen_string_literal: true

class Reynard
  # Builds and keeps context for a single request to an endpoint.
  class Context
    def initialize(specification:, operation: nil, params: nil)
      @specification = specification
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
      grouped_params.fetch('path', {}).inject(@operation.path.dup) do |path, (name, value)|
        path.gsub("{#{name}}", value.to_s)
      end
    end

    def full_path
      query? ? "#{path}?#{query}" : path
    end

    def each_url
      @specification.dig('servers').each do |server|
        yield "#{server['url']}#{full_path}"
      end
    end

    def operation(operation_name)
      self.class.new(
        specification: @specification,
        operation: @specification.operation(operation_name),
        params: @params
      )
    end

    def params(**params)
      self.class.new(
        specification: @specification,
        operation: @operation,
        params: @params ? @params.merge(params) : params
      )
    end

    def execute
      each_url do |url|
        result = perform_request(url)
        return result if result
      end
      nil
    end

    private

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
