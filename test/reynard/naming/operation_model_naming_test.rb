# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  module Naming
    class OperationModelNamingTest < Reynard::Test
      def setup
        @specifications = Dir.glob(File.join(FILES_ROOT, 'openapi/*.yml')).map do |filename|
          Specification.new(filename: filename)
        end
      end

      test 'formats a model name for all objects in the specification' do
        @specifications.each do |specification|
          specification.find_each(type: 'object') do |node|
            naming = OperationModelNaming.new(specification: specification, node: node)
            refute_nil naming.model_name
          end
        end
      end
    end
  end
end
