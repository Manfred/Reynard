# frozen_string_literal: true

require 'open3'
require 'ostruct'

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

    def service(http_request, http_response)
      case http_request.path
      when '/books'
        handle_collection(http_request, http_response)
      when %r{/books/(\d+)}
        if_none_match_value = http_request['If-None-Match']
        if_none_match = if_none_match_value ? if_none_match_value.split(',').map(&:strip) : []
        handle_member(Regexp.last_match(1).to_i, http_response, if_none_match: if_none_match)
      else
        respond_with_not_found(http_response)
      end
    end

    private

    def handle_collection(http_request, http_response)
      case http_request.request_method
      when 'GET'
        http_response.body = MultiJson.dump(all)
      when 'POST'
        book = add(MultiJson.load(http_request.body))
        http_response.body = MultiJson.dump(book)
      end
    end

    def handle_member(id, http_response, if_none_match:)
      book = find(id)
      if book
        json = MultiJson.dump(book)
        etag = %(W/"#{Digest::SHA1.hexdigest(json)}")
        if if_none_match.include?(etag)
          http_response.status = 304
        else
          http_response['Etag'] = etag
          http_response['Last-Modified'] = Time.now.httpdate
          http_response.body = json
        end
      else
        respond_with_not_found(http_response)
      end
    end

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
    @options ||= Options.new(port: 8592)
  end

  def self.run
    simple_service = new
    simple_service.run
    simple_service
  end
end

SimpleService.run if __FILE__ == $PROGRAM_NAME
