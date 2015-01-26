require 'spec_helper'

require 'hive/worker/test'

describe Hive::Worker do
  after(:each) do
    `ps aux | grep WORKER | grep -v grep | awk '{ print $2 }'`.split("\n").each do |pid|
      Process.kill 'TERM', pid.to_i
    end
  end

  describe '#initialize' do
    it 'forks a test worker' do
      worker = Hive::Worker::Test.new('name_stub' => 'TEST_WORKER')
      expect(`ps aux | grep TEST_WORKER | grep -v grep | wc -l`.to_i).to be 1
      # Clean up
      worker.stop
    end
  end

  describe '#stop' do
    it 'terminates a test worker' do
      worker = Hive::Worker::Test.new('name_stub' => 'TEST_WORKER')
      worker.stop
      sleep 1
      expect(`ps aux | grep TEST_WORKER | grep -v grep | wc -l`.to_i).to be 0
    end
  end

  describe '#running?' do
    it 'shows that a worker is running' do
      worker = Hive::Worker::Test.new('name_stub' => 'TEST_WORKER')
      expect(worker.running?).to be true
    end

    it 'shows that a worker is not running' do
      worker = Hive::Worker::Test.new('name_stub' => 'TEST_WORKER')
      worker.stop
      sleep 1
      expect(worker.running?).to be false
    end
  end
end
