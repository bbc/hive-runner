# Note, do not require 'spec_helper' as these test "require 'hive'"
# These tests only pass if they are run by themselves because the other tests
# require 'hive'
# TODO: Find a solution to this
require 'rspec'

require 'simplecov'
SimpleCov.start

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

SPEC_ROOT = File.expand_path('..', __FILE__)

describe 'require hive' do
  describe 'configuration' do
    describe 'logging' do
      it 'raises an error if the logging configuration is missing' do
        ENV['HIVE_CONFIG'] = File.expand_path('../configs/test_config_no_logging.yml', __FILE__)
        expect { require 'hive' }.to raise_error(RuntimeError)
      end

      it 'raises an error if the logging directory is missing' do
        ENV['HIVE_CONFIG'] = File.expand_path('../configs/test_config_no_log_directory.yml', __FILE__)
        expect { require 'hive' }.to raise_error(RuntimeError)
      end
    end
  end
end
