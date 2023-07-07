# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class InflectorTest < Reynard::Test
    test 'snake-cases' do
      YAML.load_file(File.join(FILES_ROOT, 'snake_case.yml')).each do |example, expected|
        assert_equal expected, Inflector.snake_case(example)
      end
    end

    test 'snake-cases symbols' do
      assert_equal 'first', Inflector.snake_case(:first)
    end

    test 'snake-cases exceptions with registered snake cases' do
      inflector = Inflector.new
      inflector.snake_cases(
        { '1st-class' => 'first_class', '#pragma' => '__pragma', '🔥' => 'fire' }
      )
      assert_equal 'regular', inflector.snake_case('regular')
      assert_equal 'first_name', inflector.snake_case('firstName')
      assert_equal 'first_class', inflector.snake_case('1st-class')
      assert_equal '__pragma', inflector.snake_case('#pragma')
      assert_equal 'fire', inflector.snake_case('🔥')
    end
  end
end
