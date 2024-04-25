# frozen_string_literal: true

class Reynard
  # Value class for details about the request.
  RequestContext = Struct.new(
    :logger,
    :base_url,
    :operation,
    :headers,
    :params,
    :body,
    :form_data,
    keyword_init: true
  ) do
    def verb
      operation&.verb
    end

    def query
      Rack::Utils.build_query(params['query']) if query_params?
    end

    def path
      return unless operation&.path

      Template.new(operation.path, params ? params.fetch('path', {}) : {}).result
    end

    def full_path
      query_params? ? "#{path}?#{query}" : path
    end

    def url
      return unless base_url

      "#{base_url}#{full_path}"
    end

    def copy(**properties)
      copy = dup
      properties.each { |attribute, value| copy.send("#{attribute}=", value) }
      copy
    end

    private

    def query_params?
      return false unless params

      !params.fetch('query', {}).empty?
    end

    def path_params?
      params&.key?('path')
    end
  end
end
