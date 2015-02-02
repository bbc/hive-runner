require 'yaml'
require 'hive/log'

# The Hive automated testing framework
module Hive
  config_file = ENV['HIVE_CONFIG'] || File.expand_path('../../config/hive-runner.yml', __FILE__)

  CONFIG = YAML.load_file(config_file)
  DAEMON_NAME = CONFIG['daemon_name'] || 'HIVE'

  if CONFIG['logging']
    LOG = Hive::Log.new
    if CONFIG['logging']['directory']
      LOG_DIRECTORY = CONFIG['logging']['directory']
      if CONFIG['logging']['main_filename']
        LOG.add_logger("#{LOG_DIRECTORY}/#{CONFIG['logging']['main_filename']}", CONFIG['logging']['main_level'] || 'INFO')
      end
      if CONFIG['logging']['console_level']
        LOG.add_logger(STDOUT, CONFIG['logging']['console_level'])
      end
    else
      fail 'Missing log directory'
    end
    if CONFIG['logging']['pids']
      PIDS_DIRECTORY = CONFIG['logging']['pids']
    else
      PIDS_DIRECTORY = LOG_DIRECTORY
    end
  else
    fail 'Missing logging section in configuration file'
  end
  LOG.info('*** HIVE STARTING ***')
end
