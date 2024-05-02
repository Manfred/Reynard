# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  module Naming
    class PropertyNamingTest < Reynard::Test
      test 'snake-cases' do
        YAML.load_file(File.join(FILES_ROOT, 'snake_case.yml')).each do |example, expected|
          assert_equal expected, PropertyNaming.snake_case(example)
        end
      end

      test 'snake-cases symbols' do
        assert_equal 'first', PropertyNaming.snake_case(:first)
      end

      test 'snake-cases exceptions with registered snake cases' do
        naming = PropertyNaming.new(
          exceptions: { '1st-class' => 'first_class', '#pragma' => '__pragma', '🔥' => 'fire' }
        )
        assert_equal 'regular', naming.call('regular')
        assert_equal 'first_name', naming.call('firstName')
        assert_equal 'first_class', naming.call('1st-class')
        assert_equal '__pragma', naming.call('#pragma')
        assert_equal 'fire', naming.call('🔥')
      end
    end
  end
end
