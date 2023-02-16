# frozen_string_literal: true

require 'net/http/persistent'
require 'forwardable'
require 'multi_json'
require 'rack'
require 'yaml'
require 'uri'

# Reynard is a convenience class for configuring an HTTP request against an
# OpenAPI specification.
class Reynard
  extend Forwardable
  def_delegators :build_context, :logger, :base_url, :operation, :headers, :params
  def_delegators :@specification, :servers

  autoload :Context, 'reynard/context'
  autoload :External, 'reynard/external'
  autoload :GroupedParameters, 'reynard/grouped_parameters'
  autoload :Http, 'reynard/http'
  autoload :Logger, 'reynard/logger'
  autoload :MediaType, 'reynard/media_type'
  autoload :Model, 'reynard/model'
  autoload :Models, 'reynard/models'
  autoload :ObjectBuilder, 'reynard/object_builder'
  autoload :Operation, 'reynard/operation'
  autoload :RequestContext, 'reynard/request_context'
  autoload :Schema, 'reynard/schema'
  autoload :SerializedBody, 'reynard/serialized_body'
  autoload :Server, 'reynard/server'
  autoload :Specification, 'reynard/specification'
  autoload :Template, 'reynard/template'
  autoload :VERSION, 'reynard/version'

  def initialize(filename:)
    @specification = Specification.new(filename:)
  end

  class << self
    # Assign an object that follows Reynard's internal request interface to mock requests or use a
    # different HTTP client.
    attr_writer :http
  end

  # Returns a value that will be used by default for Reynard's User-Agent headers. Please use
  # the +headers+ setter on the context if you want to change this.
  def self.user_agent
    "Reynard/#{Reynard::VERSION}"
  end

  # Returns Reynard's global request interface. This is a global object to allow persistent
  # connections, caching, and other features that need a persistent object in the process.
  def self.http
    @http ||= begin
      http = Net::HTTP::Persistent.new(name: 'Reynard')
      http.debug_output = $stderr if ENV['DEBUG']
      http
    end
  end

  private

  def build_context
    Context.new(specification: @specification)
  end
end
