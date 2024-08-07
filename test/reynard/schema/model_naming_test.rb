# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  class Schema
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

      test 'singularizes strings' do
        [
          %w[model model],
          %w[ducks duck],
          %w[industries industry]
        ].each do |input, expected|
          assert_equal expected, ModelNaming.singularize(input)
        end
      end

      test 'produces a model name for every schema node in every specification' do
        Dir.glob(File.join(FILES_ROOT, 'openapi/*.yml')).map do |filename|
          specification = Specification.new(filename: filename)
          specification.find_each(type: 'object') do |node|
            naming = ModelNaming.new(specification: specification, node: node)
            model_name = naming.model_name
            refute_nil model_name
            assert_kind_of(String, model_name)
            assert model_name.size > 2, model_name
          end
        end
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
          'NationalIndustryCollection',
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

    class ModelNamingTest < Reynard::Test
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
          'SectorCollection',
          ModelNaming.new(
            specification: @specification,
            node: node
          ).model_name
        )

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
          'NationalIndustryCollection',
          ModelNaming.new(
            specification: @specification,
            node: node
          ).model_name
        )
      end

      test 'formats a model name for an array item' do
        node = %w[
          paths
          /sectors
          get
          responses
          200
          content
          application/json
          schema
          items
        ]

        assert_equal(
          'Sector',
          ModelNaming.new(
            specification: @specification,
            node: node
          ).model_name
        )
      end
    end

    class SpecialModelNamingTest < Reynard::Test
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
