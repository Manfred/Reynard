# frozen_string_literal: true

require File.expand_path('lib/reynard/version', __dir__)

Gem::Specification.new do |spec|
  spec.name = 'reynard'
  spec.version = Reynard::VERSION
  spec.authors = [
    'Manfred Stienstra'
  ]
  spec.email = [
    'manfred.stienstra@nedap.com'
  ]
  spec.summary = <<-SUMMARY
  Minimal OpenAPI client.
  SUMMARY
  spec.description = <<-DESCRIPTION
  Reynard is an OpenAPI client for Ruby. It operates directly on the OpenAPI specification without
  the need to generate any source code.
  DESCRIPTION
  spec.homepage = 'https://github.com/nedap/reynard'
  spec.license = 'MIT'

  spec.files = Dir.glob('lib/**/*') + [
    'LICENSE.txt',
    'README.md'
  ]
  spec.require_paths = ['lib']

  spec.required_ruby_version = '> 2.7'

  spec.add_dependency 'multi_json'
  spec.add_dependency 'rack'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'webmock'
end
