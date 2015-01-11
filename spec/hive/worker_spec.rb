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

  describe '#queues' do
    it 'returns the list of queues for the worker' do
      queues = ['queue1', 'queue2']
      worker = Hive::Worker::Test.new(
        'name_stub' => 'TEST_WORKER',
        'queues' => queues
      )
      sleep 1
      expect(worker.queues).to eq queues
    end

    it 'returns an empty list of queues' do
      worker = Hive::Worker::Test.new(
        'name_stub' => 'TEST_WORKER'
      )
      sleep 1
      expect(worker.queues).to eq []
    end
  end

  describe '#add_queue' do
    it 'adds a new queue to the worker' do
      queues = ['queue1', 'queue2']
      worker = Hive::Worker::Test.new(
        'name_stub' => 'TEST_WORKER',
        'queues' => queues
      )
      sleep 1
      queues << 'queue3'
      worker.add_queue('queue3')
      expect(worker.queues).to match_array queues
    end

    it 'does not duplicate an existing queue' do
      queues = ['queue1', 'queue2']
      worker = Hive::Worker::Test.new(
        'name_stub' => 'TEST_WORKER',
        'queues' => queues
      )
      sleep 1
      worker.add_queue('queue2')
      expect(worker.queues).to match_array ['queue2', 'queue1']
    end
  end

  describe '#remove_queue' do
    it 'removes a queue from the worker' do
      queues = ['queue1', 'queue2']
      worker = Hive::Worker::Test.new(
        'name_stub' => 'TEST_WORKER',
        'queues' => queues
      )
      sleep 1
      worker.remove_queue('queue2')
      expect(worker.queues).to match_array ['queue1']
    end

    it 'does not change queues by removing an unknown queue' do
      queues = ['queue1', 'queue2']
      worker = Hive::Worker::Test.new(
        'name_stub' => 'TEST_WORKER',
        'queues' => queues
      )
      sleep 1
      worker.remove_queue('queue3')
      expect(worker.queues).to match_array queues
    end
  end
end
