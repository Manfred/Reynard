# frozen_string_literal: true

require 'logger'

class Reynard
  # Proxy class for a Logger object. Makes irrelevant logging actions a no-op.
  class Logger
    def initialize(logger)
      @logger = logger
    end

    def debug(&block)
      return unless @logger
      return if @logger.level > ::Logger::DEBUG

      @logger.debug(block.call)
    end

    def info(&block)
      return unless @logger
      return if @logger.level > ::Logger::INFO

      @logger.info(block.call)
    end
  end
end
