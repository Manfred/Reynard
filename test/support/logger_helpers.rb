# frozen_string_literal: true

require 'logger'

module LoggerHelpers
  def test_logger_filename
    File.join(LOG_ROOT, 'test.log')
  end

  def test_logger
    return @logger if defined?(@logger)

    FileUtils.mkdir_p(File.dirname(test_logger_filename))
    @logger = Logger.new(test_logger_filename)
    @logger.level = Logger::DEBUG
    @logger
  end
end
