# frozen_string_literal: true

require 'open3'

require 'multi_json'
require 'webrick'

class SimpleService
  Options = Struct.new(:port, keyword_init: true)

  class Servlet < WEBrick::HTTPServlet::AbstractServlet
    def initialize(*)
      super
      @books = [
        { 'id' => 1 }
      ]
    end

    def service(http_request, http_response) # rubocop:disable Metrics/MethodLength
      http_response['Content-Type'] = 'application/json'
      case http_request.path
      when '/books'
        handle_collection(http_request, http_response)
      when %r{/books/(\d+)}
        handle_member(Regexp.last_match(1).to_i, http_response)
      else
        respond_with_not_found(http_response)
      end
    rescue Exception => e # rubocop:disable Lint/RescueException
      respond_with_internal_server_error(
        http_response,
        e.class.to_s,
        e.message,
        e.backtrace
      )
    end

    private

    def handle_collection(http_request, http_response)
      case http_request.request_method
      when 'GET'
        http_response.body = MultiJson.dump(all)
      when 'POST'
        book = add(parse_book(http_request))
        http_response.body = MultiJson.dump(book)
      end
    end

    def parse_book(http_request)
      case http_request['Content-Type']
      when %r{^multipart/form-data}
        http_request.query
      else
        MultiJson.load(http_request.body)
      end
    end

    def handle_member(id, http_response)
      book = find(id)
      if book
        http_response.body = MultiJson.dump(book)
      else
        respond_with_not_found(http_response)
      end
    end

    def respond_with_not_found(http_response)
      http_response.status = 404
      http_response.body = MultiJson.dump('error' => 'not_found')
    end

    def respond_with_internal_server_error(http_response, error, message, backtrace)
      http_response.status = 500
      http_response.body = MultiJson.dump(
        'error' => error, 'message' => message, 'backtrace' => backtrace
      )
    end

    def all
      @books
    end

    def find(id)
      @books.find { |book| book['id'] == id }
    end

    def add(attributes)
      @books << attributes.merge('id' => @books.map { |book| book['id'] }.max.to_i + 1)
      @books.last
    end
  end

  def run
    trap 'INT' do
      server.shutdown
    end
    server.start
  end

  def build_server
    server = WEBrick::HTTPServer.new(Port: self.class.options.port)
    server.mount '/', Servlet
    server
  end

  def server
    @server ||= build_server
  end

  def self.options
    @options ||= Options.new(port: 8592)
  end

  def self.run
    simple_service = new
    simple_service.run
    simple_service
  end
end

SimpleService.run if __FILE__ == $PROGRAM_NAME
