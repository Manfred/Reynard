# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class GroupedParametersTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/params.yml'))
    end

    test 'includes parameters in query when specifications are not set' do
      assert_equal(
        { 'query' => { 'id' => 12 } },
        GroupedParameters.new(
          specification: @specification,
          node: ['paths', '/spaces/{name}', 'get'],
          params: { 'id' => 12 }
        ).to_h
      )
    end

    test 'raises an exception when params are nil' do
      assert_raises(NoMethodError) do
        GroupedParameters.new(
          specification: @specification,
          node: ['paths', '/spaces/{name}', 'get'],
          params: nil
        ).to_h
      end
    end

    test 'groups parameters by their place in the request' do
      assert_equal(
        {
          'path' => { 'id' => 12 },
          'query' => { 'format' => 'json', 'include' => 'author' },
          'header' => { 'Accept' => 'text/plain' },
          'cookie' => { 'authorization' => 'a9a48294' }
        },
        GroupedParameters.new(
          specification: @specification,
          node: ['paths', '/spaces', 'get'],
          params: {
            'id' => 12,
            'format' => 'json',
            'include' => 'author',
            'Accept' => 'text/plain',
            'authorization' => 'a9a48294'
          }
        ).to_h
      )
    end

    test 'groups parameters by their place in the request when specified through $ref' do
      assert_equal(
        {
          'path' => { 'name' => 'srgb', 'version' => 42 },
          'query' => { 'page' => 12 }
        },
        GroupedParameters.new(
          specification: @specification,
          node: ['paths', '/profiles/{name}/{version}', 'get'],
          params: {
            'page' => 12,
            'name' => 'srgb',
            'version' => 42
          }
        ).to_h
      )
    end
  end
end
