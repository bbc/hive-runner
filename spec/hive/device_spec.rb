require 'spec_helper'

require 'hive/device/test'

describe Hive::Device do
  after(:each) do
    `ps aux | grep TEST_WORKER | grep -v grep | awk '{ print $2 }'`.split("\n").each do |pid|
      Process.kill 'TERM', pid.to_i
    end
  end

  describe '#start' do
    it 'forks a test worker' do
      device = Hive::Device::Test.new('name_stub' => 'TEST_WORKER')
      device.start
      expect(`ps aux | grep TEST_WORKER | grep -v grep | wc -l`.to_i).to be 1
      # Clean up
      device.stop
    end
  end

  describe '#stop' do
    it 'terminates a test worker' do
      device = Hive::Device::Test.new('name_stub' => 'TEST_WORKER')
      device.start
      sleep 1
      device.stop
      sleep 1
      expect(`ps aux | grep TEST_WORKER | grep -v grep | wc -l`.to_i).to be 0
    end
  end

  describe '#running?' do
    it 'shows that a worker is running' do
      device = Hive::Device::Test.new('name_stub' => 'TEST_WORKER')
      device.start
      expect(device.running?).to be true
      # Clean up
      device.stop
    end

    it 'shows that a worker is not running' do
      device = Hive::Device::Test.new('name_stub' => 'TEST_WORKER')
      device.start
      sleep 1
      device.stop
      sleep 1
      expect(device.running?).to be false
    end
  end
end
