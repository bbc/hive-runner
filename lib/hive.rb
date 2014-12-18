require 'yaml'
#require 'hive/log'

module Hive
  config_file = ENV['HIVE_CONFIG'] || '/opt/devicehive/conf/device_hive.yml'

  CONFIG = YAML.load_file(File.expand_path(config_file, __FILE__))

  #if CONFIG['logging']
  #  LOG = Hive::Log.new()
  #  if CONFIG['logging']['directory']
  #    dir = CONFIG['logging']['directory']
  #    if CONFIG['logging']['main_filename']
  #      LOG.add_logger( "#{dir}/#{CONFIG['logging']['main_filename']}", CONFIG['logging']['main_level'] || 'INFO' )
  #    end
  #    if CONFIG['logging']['console_level']
  #      LOG.add_logger( STDOUT, CONFIG['logging']['console_level'] )
  #    end
  #  else
  #    raise "Missing log directory"
  #  end
  #else
  #  raise "Missing logging section in configuration file"
  #end

end
