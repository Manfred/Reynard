# frozen_string_literal: true

require 'fileutils'

class Reynard
  module Store
    # Simple file-based cache storage. Not thread-safe and probably too slow for regular use.
    class Disk
      def initialize(path:)
        @path = File.expand_path(path)
      end

      def read(key)
        File.read(filename(key))
      rescue Errno::ENOENT
        nil
      end

      def write(key, value)
        filename = filename(key)
        FileUtils.mkdir_p(File.dirname(filename))
        File.binwrite(filename, value)
      end

      def clear
        FileUtils.rm_rf(@path)
      end

      private

      def filename(key)
        File.join(@path, key)
      end
    end
  end
end
