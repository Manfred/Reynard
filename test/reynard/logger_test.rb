# frozen_string_literal: true

require_relative '../test_helper'

class Reynard
  class LoggerBlankTest < Reynard::Test
    def setup
      @logger = Reynard::Logger.new(nil)
    end

    test 'does nothing when logging at debug level' do
      @logger.debug { raise }
    end

    test 'does nothing when logging at info level' do
      @logger.info { raise }
    end
  end

  class LoggerDebugTest < Reynard::Test
    def setup
      @out = StringIO.new
      logger = ::Logger.new(@out)
      logger.level = ::Logger::DEBUG
      @logger = Reynard::Logger.new(logger)
    end

    test 'writes debug log items to the logger' do
      @logger.debug { 'Hi!' }
      assert @out.string.include?('Hi!')
    end

    test 'writes info log items to the logger' do
      @logger.info { 'Hi!' }
      assert @out.string.include?('Hi!')
    end
  end

  class LoggerInfoTest < Reynard::Test
    def setup
      @out = StringIO.new
      logger = ::Logger.new(@out)
      logger.level = ::Logger::INFO
      @logger = Reynard::Logger.new(logger)
    end

    test 'does not write debug log items to the logger' do
      @logger.debug { 'Hi!' }
      refute @out.string.include?('Hi!')
    end

    test 'writes info log items to the logger' do
      @logger.info { 'Hi!' }
      assert @out.string.include?('Hi!')
    end
  end
end
