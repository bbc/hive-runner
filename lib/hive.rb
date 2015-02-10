require 'chamber'
require 'hive/log'

# The Hive automated testing framework
module Hive
  Chamber.load(
    basepath: ENV['HIVE_CONFIG'] || File.expand_path('../../config', __FILE__),
    namespaces: {
      environment: ENV['HIVE_ENVIRONMENT'] || 'test'
    }
  )

  DAEMON_NAME = Chamber.env.daemon_name? ? Chamber.env.daemon_name : 'HIVE'

#  LOG = Hive::Log.new
  if Chamber.env.logging?
    if Chamber.env.logging.directory?
      LOG_DIRECTORY = Chamber.env.logging.directory
#      if Chamber.env.logging.main_filename?
#        LOG.add_logger("#{LOG_DIRECTORY}/#{Chamber.env.logging.main_filename}", Chamber.env.logging.main_level || 'INFO')
#      end
#      if Chamber.env.logging.console_level?
#        LOG.add_logger(STDOUT, Chamber.env.logging.console_level)
#      end
    else
      fail 'Missing log directory'
    end
    if Chamber.env.logging.pids?
      PIDS_DIRECTORY = Chamber.env.logging.pids
    else
      PIDS_DIRECTORY = LOG_DIRECTORY
    end
  else
    fail 'Missing logging section in configuration file'
  end
#  LOG.info("Logger: #{LOG.inspect}")

  def self.logger
    if ! @logger
      @logger = Hive::Log.new
      if Chamber.env.logging.main_filename?
        @logger.add_logger("#{LOG_DIRECTORY}/#{Chamber.env.logging.main_filename}", Chamber.env.logging.main_level || 'INFO')
      end
      if Chamber.env.logging.console_level?
        @logger.add_logger(STDOUT, Chamber.env.logging.console_level)
      end
    end
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end
end
