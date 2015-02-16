require 'chamber'
require 'hive/log'
require 'devicedb_comms'

# The Hive automated testing framework
module Hive
  Chamber.load(
    basepath: ENV['HIVE_CONFIG'] || File.expand_path('../../config', __FILE__),
    namespaces: {
      environment: ENV['HIVE_ENVIRONMENT'] || 'test'
    }
  )

  DAEMON_NAME = Chamber.env.daemon_name? ? Chamber.env.daemon_name : 'HIVE'

  if Chamber.env.logging?
    if Chamber.env.logging.directory?
      LOG_DIRECTORY = Chamber.env.logging.directory
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

  def self.config
    Chamber.env
  end

  def self.logger
    if ! @logger
      @logger = Hive::Log.new

      if Hive.config.logging.main_filename?
        @logger.add_logger("#{LOG_DIRECTORY}/#{Hive.config.logging.main_filename}", Chamber.env.logging.main_level? ? Chamber.env.logging.main_level : 'INFO')
      end
      if Hive.config.logging.console_level?
        @logger.add_logger(STDOUT, Hive.config.logging.console_level)
      end
    end
    @logger
  end

  def self.devicedb
    @devicedb ||= DeviceDBComms::Device.new(
      Hive.config.network.devicedb,
      Hive.config.network.cert
    )
  end
end
