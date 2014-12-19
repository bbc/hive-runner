require 'yaml'

# The Hive automated testing framework
module Hive
  config_file = ENV['HIVE_CONFIG'] || '../../config/hive-runner.yml'

  CONFIG = YAML.load_file(File.expand_path(config_file, __FILE__))
end
