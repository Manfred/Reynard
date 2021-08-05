# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class GroupedParametersTest < Reynard::Test
    test 'includes parameters in query when specifications are not set' do
      assert_equal(
        { 'query' => { 'id' => 12 } },
        GroupedParameters.new(nil, { 'id' => 12 }).to_h
      )
    end

    test 'raises an exception when params are nil' do
      assert_raises(NoMethodError) do
        GroupedParameters.new([], nil).to_h
      end
    end

    test 'groups parameters by their place in the request' do
      assert_equal(
        {
          'path' => { 'id' => 12 },
          'query' => { 'format' => 'json', 'include' => 'author' },
          'header' => { 'X-Customer-Code' => 'XX7234' },
          'cookie' => { 'authorization' => 'a9a48294' }
        },
        GroupedParameters.new(
          [
            { 'name' => 'id', 'in' => 'path' },
            { 'name' => 'format', 'in' => 'query' },
            { 'name' => 'X-Customer-Code', 'in' => 'header' },
            { 'name' => 'authorization', 'in' => 'cookie' }
          ],
          {
            'id' => 12,
            'format' => 'json',
            'include' => 'author',
            'X-Customer-Code' => 'XX7234',
            'authorization' => 'a9a48294'
          }
        ).to_h
      )
    end
  end
end
