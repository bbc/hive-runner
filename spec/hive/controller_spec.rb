require 'spec_helper'

require 'hive/controller/test'

describe Hive::Controller do
  describe '#check_workers' do
    it 'starts a stopped worker' do
      shell = Hive::Controller::Test.new('max_workers' => 1)
      shell.check_workers
      expect(shell.instance_variable_get(:@workers)[0]).to be_a Hive::Worker::Test
    end

    it 'starts multiple workers' do
      shell = Hive::Controller::Test.new('max_workers' => 3)
      shell.check_workers
      expect(shell.instance_variable_get(:@workers).length).to be 3
    end

    it 'does not start a worker' do
      shell = Hive::Controller::Test.new('max_workers' => 0)
      shell.check_workers
      expect(shell.instance_variable_get(:@workers).length).to be 0
    end

    it 'does not start an extra worker' do
      shell = Hive::Controller::Test.new('max_workers' => 1)
      shell.check_workers
      shell.check_workers
      expect(shell.instance_variable_get(:@workers).length).to be 1
    end
  end
end
