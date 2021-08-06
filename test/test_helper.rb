# frozen_string_literal: true

GEM_ROOT = File.expand_path('..', __dir__)
TEST_ROOT = __dir__
FIXTURES_ROOT = "#{TEST_ROOT}/fixtures"
FILES_ROOT = "#{TEST_ROOT}/files"
SUPPORT_ROOT = "#{TEST_ROOT}/support"

require 'minitest/autorun'
require 'webmock/minitest'
require 'ostruct'

$LOAD_PATH << File.expand_path('../lib', __dir__)

require 'reynard'

def load_support
  Dir[File.join(SUPPORT_ROOT, '**/*.rb')].sort.each { |file| require file }
end
load_support

class Reynard
  class Test < Minitest::Test
    def self.test(description, &block)
      define_method("test_#{description}", &block)
    end

    private

    def fixture_file(path)
      File.join(FILES_ROOT, path)
    end
  end
end
