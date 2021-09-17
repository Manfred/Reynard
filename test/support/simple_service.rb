# frozen_string_literal: true

require 'open3'
require 'ostruct'

require 'multi_json'
require 'webrick'

class SimpleService
  class Servlet < WEBrick::HTTPServlet::AbstractServlet
    def initialize(*)
      super
      @books = [
        { 'id' => 1 }
      ]
    end

    def service(http_request, http_response)
      case http_request.path
      when '/books'
        case http_request.request_method
        when 'GET'
          http_response.body = MultiJson.dump(all)
        when 'POST'
          book = add(MultiJson.load(http_request.body))
          http_response.body = MultiJson.dump(book)
        end
      when %r{/books/(\d+)}
        book = find(Regexp.last_match(1).to_i)
        if book
          http_response.body = MultiJson.dump(book)
        else
          respond_with_not_found(http_response)
        end
      else
        respond_with_not_found(http_response)
      end
    end

    private

    def respond_with_not_found(http_response)
      http_response.status = 404
      http_response.body = MultiJson.dump('error' => 'not_found')
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
    @options ||= OpenStruct.new(port: 8592)
  end

  def self.run
    simple_service = new
    simple_service.run
    simple_service
  end
end

SimpleService.run if __FILE__ == $PROGRAM_NAME
