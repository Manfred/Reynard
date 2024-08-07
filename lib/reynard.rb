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
  def_delegators(
    :build_context,
    :base_url,
    :operation,
    :params,
    :body,
    :headers,
    :logger,
    :serializer,
    :deserializer,
    :property_naming,
    :model_registry,
    :model_naming
  )
  def_delegators :@specification, :servers

  autoload :ClassBuilder, 'reynard/class_builder'
  autoload :Collection, 'reynard/collection'
  autoload :Content, 'reynard/content'
  autoload :Context, 'reynard/context'
  autoload :Deserializers, 'reynard/deserializers'
  autoload :External, 'reynard/external'
  autoload :GroupedParameters, 'reynard/grouped_parameters'
  autoload :Http, 'reynard/http'
  autoload :MediaType, 'reynard/media_type'
  autoload :Model, 'reynard/model'
  autoload :Models, 'reynard/models'
  autoload :Naming, 'reynard/naming'
  autoload :ObjectBuilder, 'reynard/object_builder'
  autoload :Operation, 'reynard/operation'
  autoload :Property, 'reynard/property'
  autoload :ResponseContext, 'reynard/response_context'
  autoload :RequestContext, 'reynard/request_context'
  autoload :Serializers, 'reynard/serializers'
  autoload :Schema, 'reynard/schema'
  autoload :SerializerSelection, 'reynard/serializer_selection'
  autoload :Server, 'reynard/server'
  autoload :Specification, 'reynard/specification'
  autoload :Template, 'reynard/template'
  autoload :VERSION, 'reynard/version'

  def initialize(filename:)
    @specification = Specification.new(filename: filename)
  end

  class << self
    # Assign an object that follows Reynard's internal request interface to mock requests or use a
    # different HTTP client.
    attr_writer :http
    # Assign a model registry instance that will be used by every response context.
    attr_writer :model_registry
    # Assign a model naming class that will be used by every response context.
    attr_writer :model_naming
  end

  # Returns a value that will be used by default for Reynard's User-Agent headers. Please use
  # the +headers+ setter on the context if you want to change this.
  def self.user_agent
    "Reynard/#{Reynard::VERSION}"
  end

  # Returns supported request body serializers as a Hash-like object keyed on the content-type.
  def self.serializers
    {
      'application/json' => Reynard::Serializers::ApplicationJson,
      'multipart/form-data' => Reynard::Serializers::MultipartFormData,
      'text/plain' => Reynard::Serializers::TextPlain
    }.freeze
  end

  # Returns supported response body deserializers as a Hash-like object keyed on the content-type.
  def self.deserializers
    {
      'application/json' => Reynard::Deserializers::ApplicationJson
    }.freeze
  end

  def self.model_registry
    @model_registry ||= Reynard::Naming::ModelRegistry.new
  end

  def self.model_naming
    @model_naming || Reynard::Naming::NodeModelNaming
  end

  def self.property_naming
    @property_naming || Reynard::Naming::PropertyNaming.new
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
