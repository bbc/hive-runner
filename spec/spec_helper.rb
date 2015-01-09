require 'rspec'

require 'simplecov'
SimpleCov.start

ENV['HIVE_CONFIG'] = File.expand_path('../test_config.yml', __FILE__)
$LOAD_PATH << File.expand_path('../../lib', __FILE__)
$LOAD_PATH << File.expand_path('../helper_lib', __FILE__)

require 'hive'

SPEC_ROOT = File.expand_path('..', __FILE__)
