# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  class Specification
    class FinderTest < Reynard::Test
      def setup
        @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
      end

      test 'finds all nodes in a specification that match a type' do
        query = Query.new(type: 'object')
        finder = Finder.new(specification: @specification, query:)
        found = []
        finder.find_each do |node|
          found << node.join('::')
        end
        assert_equal(
          [
            'paths::/books::get::responses::200::content::application/json::schema::items',
            'paths::/books::get::responses::default::content::application/json::schema',
            'paths::/books::post::requestBody::content::application/json::schema',
            'paths::/books::post::requestBody::content::multipart/form-data::schema',
            'paths::/books::post::responses::200::content::application/json::schema',
            'paths::/books::post::responses::default::content::application/json::schema',
            'paths::/books/{id}::get::responses::200::content::application/json::schema',
            'paths::/books/{id}::get::responses::default::content::application/json::schema',
            'paths::/books/{id}::put::responses::200::content::application/json::schema',
            'paths::/books/{id}::put::responses::default::content::application/json::schema',
            'paths::/books/{id}::patch::responses::200::content::application/json::schema',
            'paths::/books/{id}::patch::responses::default::content::application/json::schema',
            'paths::/books/sample::get::responses::200::content::application/json::schema',
            'paths::/books/sample::get::responses::default::content::application/json::schema',
            'paths::/search/books::get::responses::200::content::application/json::schema::items',
            'paths::/search/books::get::responses::default::content::application/json::schema',
            'components::schemas::Book',
            'components::schemas::BookFormData',
            'components::schemas::Books::items',
            'components::schemas::Error'
          ],
          found
        )
      end

      test 'does not find nodes for query without match' do
        query = Query.new(type: 'unknown')
        finder = Finder.new(specification: @specification, query:)
        finder.find_each { raise 'Must not find anything' }
      end
    end
  end
end
