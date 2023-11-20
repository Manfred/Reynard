# frozen_string_literal: true

require_relative '../../test_helper'

class Reynard
  module Store
    class DiskTest < Reynard::Test
      def setup
        # We use the global builder for the test store so it's cleared inbetween examples.
        @store = test_file_store
      end

      test "returns nil when a key doesn't exist in the store" do
        assert_nil @store.read('storage-key')
      end

      test 'reads data back from the store after writing it' do
        assert @store.write('storage-key', 'value')
        assert_equal 'value', @store.read('storage-key')
      end

      test 'clears the disk cache' do
        assert @store.write('storage/1/key.info', '{}')
        assert @store.write('storage/1/key.data', 'value1')
        assert @store.write('storage/2/key.info', '{}')
        assert @store.write('storage/2/key.data', 'value2')
        assert_equal 'value2', @store.read('storage/2/key.data')
        @store.clear
        assert_nil @store.read('storage/2/key.data')
      end
    end
  end
end
