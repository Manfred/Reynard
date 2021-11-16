# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  class Http
    # Response is mostly tested through Context because replicating a RequestContext without a full
    # specification is kind of cumbersome.
    class ResponseTest < Reynard::Test
      def setup
        @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
        @request_context = RequestContext.new(
          base_url: @specification.default_base_url,
          headers: {},
          operation: @specification.operation('sampleBook')
        )
        @body = '{"id":12}'

        response_class = Net::HTTPResponse::CODE_TO_OBJ['200']
        @http_response = response_class.new('HTTP/1.1', '200', 'OK')
        @http_response['Content-Type'] = 'application/json'
        @http_response['X-Sample'] = '👋'
        @http_response.instance_variable_set('@read', true)
        @http_response.instance_variable_set('@body', @body)

        @response = Response.new(
          specification: @specification,
          request_context: @request_context,
          http_response: @http_response
        )
      end

      test 'forwards methods to the HTTP response' do
        assert_equal '200', @response.code
        assert_equal 'application/json', @response.content_type
        assert_equal '👋', @response['X-Sample']
        assert_equal @body, @response.body
      end

      test 'builds a response object' do
        assert_equal 12, @response.object.id
      end
    end
  end
end
