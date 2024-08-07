# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class ClassBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
      @node = %w[
        paths
        /books/{id}
        get
        responses
        200
        content
        application/json
        schema
      ]
      @schema = Schema.new(
        specification: @specification,
        node: @node
      )
      @response_context = ResponseContext.build.copy(
        property_naming: Reynard::Naming::PropertyNaming.new(
          exceptions: { 'tag' => 'object_tag' }
        )
      )
      @class_builder = ClassBuilder.new(response_context: @response_context, schema: @schema)
    end

    test 'builds a class with accessor for its properties' do
      model_class = @class_builder.call
      assert_equal @schema.properties, model_class.properties

      model = model_class.new(
        { 'name' => 'Erebus', 'tag' => 'asim2' },
        @response_context
      )
      assert_equal 'Erebus', model.name

      # Name from the property naming exception
      assert_equal 'asim2', model.object_tag
      assert_nil model['object_tag']
      assert_equal 'asim2', model.try(:object_tag)

      # Original property happens to also be a valid method name.
      assert_equal 'asim2', model.tag
      assert_equal 'asim2', model['tag']
      assert_equal 'asim2', model.try(:tag)
    end
  end

  class NestedClassBuilderTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/external.yml'))
      @node = %w[
        paths
        /authors/{id}
        get
        responses
        200
        content
        application/json
        schema
      ]
      @schema = Schema.new(
        specification: @specification,
        node: @node
      )
      @response_context = ResponseContext.build.copy(
        property_naming: Reynard::Naming::PropertyNaming.new(
          exceptions: { 'tag' => 'object_tag' }
        )
      )
      @class_builder = ClassBuilder.new(response_context: @response_context, schema: @schema)
    end

    test 'builds a class with accessor for its properties' do
      model_class = @class_builder.call
      assert_equal @schema.properties, model_class.properties

      model = model_class.new(
        {
          'id' => 144,
          'name' => 'Rick Remender',
          'bio' => {
            'age' => 51
          }
        },
        @response_context
      )
      assert_equal 144, model.id
      assert_equal 'Rick Remender', model.name
      assert_equal 51, model.bio.age
    end
  end

  class ClassBuilderArrayTest < Reynard::Test
    def setup
      @specification = Specification.new(filename: fixture_file('openapi/simple.yml'))
      @node = %w[
        paths
        /books
        get
        responses
        200
        content
        application/json
        schema
      ]
      @schema = Schema.new(
        specification: @specification,
        node: @node
      )
      @response_context = ResponseContext.build
      @class_builder = ClassBuilder.new(response_context: @response_context, schema: @schema)
    end

    test 'builds a class that can be iterated with model instances' do
      model = @class_builder.call.new
      assert_kind_of Array, model
      model << Reynard::Model.new({}, @response_context)
      model << Reynard::Model.new({}, @response_context)
      assert_equal 2, model.size
    end
  end

  class ClassBuilderSanitationTest < Reynard::Test
    test "ensures that malicious property names can't break our property accessors" do
      assert_equal('name', ClassBuilder.sanitize_name('name'))
      assert_equal('na\"me', ClassBuilder.sanitize_name('na"me'))
      assert_equal('na\\\"me', ClassBuilder.sanitize_name('na\\"me'))
    end
  end
end
