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
    end

    class RegressionModelNamingTest < Reynard::Test
      EXPECTED = {
        'bare' => [],
        'external' => %w[Author Bio Error Author Bio Author Bio Error AuthorsCollection],
        'minimal' => %w[Spaceship SpaceshipCollection],
        'naming' => %w[
          Sector Subsector IndustryGroup Industry NationalIndustry Art NationalIndustry
          SectorCollection SubsectorsCollection IndustryGroupsCollection IndustriesCollection
          NationalIndustriesCollection NationalIndustryCollection NationalIndustryCollection
        ],
        'nested' => %w[
          Library Book Author Error Library Book Author Book Author Error
          BooksCollection BooksCollection
        ],
        'params' => %w[],
        'simple' => %w[
          Book Error Book BookFormData Book Error Book Error Book Error
          Book Error Book Error Book Error Book Bookformdata Book Error
          BooksCollection BooksCollection BooksCollection
        ],
        'titled' => %w[ISBN IsbnCollection],
        'weird' => %w[
          HowdyPardner AFRootWithInThe Fugol Bird Duckbill Duckbill HowdyPardner
          FugolCollection BirdsCollection DuckbillCollection
        ]
      }.freeze

      test 'produces a model name for every schema node in every specification' do
        Dir.glob(File.join(FILES_ROOT, 'openapi/*.yml')).map do |filename|
          example_name = File.basename(filename, '.yml')
          generated = []

          specification = Specification.new(filename:)

          specification.find_each(type: 'object') do |node|
            naming = ModelNaming.new(specification:, node:)
            model_name = naming.model_name
            generated << model_name

            refute_nil model_name
            assert_kind_of(String, model_name)
            assert model_name.size > 2, model_name
          end

          specification.find_each(type: 'array') do |node|
            naming = ModelNaming.new(specification:, node:)
            model_name = naming.model_name
            generated << model_name

            refute_nil model_name
            assert_kind_of(String, model_name)
            assert model_name.size > 2, model_name
          end

          assert_equal(EXPECTED.fetch(example_name), generated, "In filename: #{filename}")
        end
      end
    end
  end
end
