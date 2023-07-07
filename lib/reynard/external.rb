# frozen_string_literal: true

require 'rack'

class Reynard
  # Loads external references.
  class External
    def initialize(path:, ref:)
      @path = path
      @relative_path, @anchor = ref.split('#', 2)
      @filename = File.expand_path(@relative_path, @path)
    end

    def path
      return [] unless @anchor

      @anchor.split('/')[1..]
    end

    def data
      File.open(filename, encoding: 'UTF-8') do |file|
        YAML.safe_load(file, aliases: true)
      end
    end

    def filesystem_path
      File.dirname(@filename)
    end

    private

    def filename
      return @filename if @filename.start_with?(@path)

      raise 'You are only allowed to reference files relative to the specification file.'
    end
  end
end
