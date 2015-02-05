require 'rspec'
require 'spec_helper'

describe 'require hive' do
  describe 'configuration' do
    describe 'logging' do
      it 'raises an error if the logging configuration is missing' do
        ENV['HIVE_ENVIRONMENT'] = 'no_logging_section'
        expect { load File.expand_path('../../lib/hive.rb', __FILE__) }.to raise_error(RuntimeError)
      end

      it 'raises an error if the logging directory is missing' do
        ENV['HIVE_ENVIRONMENT'] = 'no_log_directory'
        expect { load File.expand_path('../../lib/hive.rb', __FILE__) }.to raise_error(RuntimeError)
      end
    end
  end
end
