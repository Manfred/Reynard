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
      end

      def response(code, message)
        response_class = Net::HTTPResponse::CODE_TO_OBJ[code]
        @http_response = response_class.new('HTTP/1.1', code, message)
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
        response = response('200', 'OK')
        assert_equal '200', response.code
        assert_equal 'application/json', response.content_type
        assert_equal '👋', response['X-Sample']
        assert_equal @body, response.body
      end

      test 'returns the parse body' do
        response = response('200', 'OK')
        assert_equal({ 'id' => 12 }, response.parsed_body)
      end

      test 'builds a response object' do
        response = response('200', 'OK')
        assert_equal 12, response.object.id
      end

      test 'response code in the 1xx range indicates an informational response' do
        response = response('100', 'Continue')
        assert response.informational?
        refute response.success?
        refute response.redirection?
        refute response.client_error?
        refute response.server_error?
      end

      test 'response code in the 2xx range indicates a successful response' do
        response = response('204', 'No Content')
        refute response.informational?
        assert response.success?
        refute response.redirection?
        refute response.client_error?
        refute response.server_error?
      end

      test 'response code in the 3xx range indicates a redirection' do
        response = response('308', 'Permanent Redirect')
        refute response.informational?
        refute response.success?
        assert response.redirection?
        refute response.client_error?
        refute response.server_error?
      end

      test 'response code in the 4xx range indicates a client error' do
        response = response('404', 'Not Found')
        refute response.informational?
        refute response.success?
        refute response.redirection?
        assert response.client_error?
        refute response.server_error?
      end

      test 'response code in the 5xx range indicates a server error' do
        response = response('500', 'Internal Server Error')
        refute response.informational?
        refute response.success?
        refute response.redirection?
        refute response.client_error?
        assert response.server_error?
      end
    end
  end
end
