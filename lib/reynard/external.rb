# frozen_string_literal: true

require 'rack'

class Reynard
  # Loads data for external references from disk.
  class External
    # Build a new external reference loader.
    #
    # @param basepath [String] base path of the OpenAPI specification, we never load any files
    #        higher in the directory tree
    # @param path [String] base path of the current file, used to resolve relative paths
    # @param ref [String] the $ref value we actually resolve
    def initialize(basepath:, path:, ref:)
      @basepath = basepath
      @path = path
      @relative_path, @anchor = ref.split('#', 2)
      @filename = File.expand_path(@relative_path, @path)
    end

    def path
      return [] unless @anchor

      # Remove explicit absolute (ie. /) and explicitly relative (ie. ./) instructions from the
      # path expression because we're starting at the root of an external file. We currently don't
      # support the // syntax.
      @anchor.to_s.gsub(%r{\A\.?/}, '').split('/')
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
      return @filename if @filename.start_with?(@basepath)

      raise 'You are only allowed to reference files relative to the specification file.'
    end
  end
end
