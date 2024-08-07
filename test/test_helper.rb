# frozen_string_literal: true

GEM_ROOT = File.expand_path('..', __dir__)
TEST_ROOT = __dir__
FIXTURES_ROOT = "#{TEST_ROOT}/fixtures".freeze
FILES_ROOT = "#{TEST_ROOT}/files".freeze
SUPPORT_ROOT = "#{TEST_ROOT}/support".freeze

require 'minitest/autorun'
require 'webmock/minitest'
require 'ostruct'
require 'logger'

$LOAD_PATH << File.expand_path('../lib', __dir__)

require 'reynard'

def load_support
  Dir[File.join(SUPPORT_ROOT, '**/*.rb')].each { |file| require file }
end
load_support

class Reynard
  class Test < Minitest::Test
    include Assertions

    def teardown
      remove_constants
    end

    def self.test(description, &)
      define_method("test_#{description}", &)
    end

    private

    def fixture_file(path)
      File.join(FILES_ROOT, path)
    end

    def remove_constants
      Reynard::Models.constants.each do |constant|
        Reynard::Models.send(:remove_const, constant)
      end
    end
  end
end
