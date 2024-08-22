# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ExternalTest < Reynard::Test
    test 'raises an exception when attempting to access a file not relative to specification' do
      assert_raises(RuntimeError) do
        External.new(basepath: FILES_ROOT, path: FILES_ROOT, ref: '../../../passwords.txt').data
      end
    end

    test 'loads data from a schema relative to the current path' do
      basepath = File.join(FILES_ROOT, 'openapi')
      path = File.join(FILES_ROOT, 'openapi/schemas')

      data = External.new(basepath:, path:, ref: 'author.yml').data
      assert_equal 'Author', data['title']
    end

    test 'loads data from a schema with an explicity relative path' do
      path = File.join(FILES_ROOT, 'openapi')
      data = External.new(basepath: path, path:, ref: './schemas/author.yml').data
      assert_equal 'Author', data['title']
    end

    test 'loads data from a schema with a relative path higher in the directory structure' do
      basepath = File.join(FILES_ROOT, 'openapi')
      path = File.join(FILES_ROOT, 'openapi/schemas/v1/home')

      data = External.new(basepath:, path:, ref: '../../../schemas/author.yml').data
      assert_equal 'Author', data['title']
    end

    test 'returns an empty path when there is no anchor in the ref' do
      path = File.join(FILES_ROOT, 'openapi')
      external = External.new(basepath: path, path:, ref: './schemas/author.yml')
      assert_equal [], external.path
    end

    test 'returns a path when there is an anchor in the ref' do
      path = File.join(FILES_ROOT, 'openapi')
      external = External.new(basepath: path, path:, ref: './schemas/author.yml#/properties/id')
      assert_equal %w[properties id], external.path
    end

    test 'returns a path when there is a relative anchor in the ref' do
      path = File.join(FILES_ROOT, 'openapi')
      external = External.new(basepath: path, path:, ref: './schemas/author.yml#properties/id')
      assert_equal %w[properties id], external.path
    end

    test 'returns a path when there is an explicitly relative anchor in the ref' do
      path = File.join(FILES_ROOT, 'openapi')
      external = External.new(basepath: path, path:, ref: './schemas/author.yml#./properties/id')
      assert_equal %w[properties id], external.path
    end
  end
end
