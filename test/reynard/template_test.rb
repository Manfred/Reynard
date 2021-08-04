# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class TemplateTest < Reynard::Test
    test 'raises an exception when template contains undefined variables' do
      assert_raises(KeyError) { Template.new('/{undefined}', {}).result }
    end

    test 'replaces simple variables in a template' do
      assert_equal '/books/12', Template.new('/books/{id}', { 'id' => 12 }).result
    end

    test 'creates a safe request path' do
      assert_equal '/emoji/%F0%9F%9A%B2', Template.new('/emoji/{emo}', { 'emo' => '🚲' }).result
    end
  end
end
