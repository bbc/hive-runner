require 'spec_helper'
require 'hive/file_system'

RSpec.describe Hive::FileSystem do

  describe '.new' do
    before(:all) do
      `touch test.sh`
      `zip test.zip test.sh`
    end

    after(:all) do
      `rm test.zip test.sh`
    end

    it 'checks zip file integrity correctly' do
      expect(Hive::FileSystem.new(0, Dir.mktmpdir, Hive::Log.new).check_build_integrity('test.zip')).to be true
    end

  end
end