# frozen_string_literal: true

require 'multi_json'
require 'rack'

# Reynard is a convenience class for configuring an HTTP request against an
# OpenAPI specification.
class Reynard
  extend Forwardable
  def_delegators :build_context, :operation, :params

  autoload :Context, 'reynard/context'
  autoload :Http, 'reynard/http'
  autoload :Operation, 'reynard/operation'
  autoload :Specification, 'reynard/specification'
  autoload :VERSION, 'reynard/version'

  def initialize(filename:)
    @specification = Specification.new(filename: filename)
  end

  private

  def build_context
    Context.new(specification: @specification)
  end
end
