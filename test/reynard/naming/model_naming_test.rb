# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  module Naming
    class ModelNamingTest < Reynard::Test
      test 'formats a model name based on the title specification' do
        {
          'AdministrationAgreement' => 'AdministrationAgreement',
          'Library' => 'Library',
          'ISBN' => 'ISBN',
          ' A %2F root with 🚕 in the ' => 'AFRootWithInThe'
        }.each do |model_name, expected|
          assert_equal expected, ModelNaming.title_model_name(model_name)
        end
      end

      test 'does not return a model name based on a missing title' do
        assert_nil ModelNaming.title_model_name(nil)
      end

      test 'formats a model name based on a ref to a schema' do
        {
          '#/components/schemas/Library' => 'Library',
          './schemas/author.yml' => 'Author',
          '#/components/schemas/%20howdy%E2%9A%A0%EF%B8%8F.Pardner' => 'HowdyPardner',
          '#/components/schemas/Service.Subscription' => 'ServiceSubscription'
        }.each do |ref, expected|
          assert_equal expected, ModelNaming.ref_model_name(ref)
        end
      end

      test 'does not return a model name based on a missing ref' do
        assert_nil ModelNaming.ref_model_name(nil)
      end
    end

    class TitleModelNamingTest < Reynard::Test
      def setup
        @specification = Specification.new(filename: fixture_file('openapi/naming.yml'))
        @node = %w[
          paths
          /sectors/arts
          get
          responses
          200
          content
          application/json
          schema
        ]
      end

      test 'formats a model name based on the node to the schema' do
        assert_equal(
          'NationalIndustry',
          ModelNaming.new(
            specification: @specification,
            node: @node
          ).model_name
        )
      end
    end

    class RefModelNamingTest < Reynard::Test
      def setup
        @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
      end

      test 'formats a model name based on the ref to the schema' do
        node = %w[
          paths
          /books/{id}
          get
          responses
          200
          content
          application/json
          schema
        ]

        assert_equal(
          'Book',
          ModelNaming.new(
            specification: @specification,
            node: node
          ).model_name
        )
      end
    end

    class NodeModelNamingTest < Reynard::Test
      def setup
        @specification = Specification.new(filename: fixture_file('openapi/naming.yml'))
      end

      test 'formats a model name based on the node to the schema' do
        node = %w[
          paths
          /sectors
          get
          responses
          200
          content
          application/json
          schema
        ]

        assert_equal(
          'Sector',
          ModelNaming.new(
            specification: @specification,
            node: node
          ).model_name
        )
      end

      test 'formats a model name based on the node to the schemas' do
        node = %w[
          paths
          /national_industries
          get
          responses
          200
          content
          application/json
          schema
        ]

        assert_equal(
          'NationalIndustrie',
          ModelNaming.new(
            specification: @specification,
            node: node
          ).model_name
        )
      end
    end

    class SpecialNodeModelNamingTest < Reynard::Test
      def setup
        @specification = Specification.new(filename: fixture_file('openapi/weird.yml'))
      end

      test 'formats a model name based on property name for an array item' do
        node = %w[
          paths
          /fugol
          get
          responses
          200
          content
          application/json
          schema
          items
          properties
          birds
          items
        ]

        assert_equal(
          'Bird',
          ModelNaming.new(
            specification: @specification,
            node: node
          ).model_name
        )
      end

      test 'formats a model name based on the request path when node has no property name' do
        node = %w[
          paths
          /duckbills/{id}
          get
          responses
          200
          content
          application/json
          schema
        ]

        assert_equal(
          'Duckbill',
          ModelNaming.new(
            specification: @specification,
            node: node
          ).model_name
        )
      end

      test 'formats a model name based on the request path when array item has no property name' do
        node = %w[
          paths
          /duckbills
          get
          responses
          200
          content
          application/json
          schema
          items
        ]

        assert_equal(
          'Duckbill',
          ModelNaming.new(
            specification: @specification,
            node: node
          ).model_name
        )
      end
    end
  end
end
