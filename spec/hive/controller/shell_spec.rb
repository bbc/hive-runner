require 'spec_helper'

require 'hive/controller/shell'

describe Hive::Controller::Shell do

  describe '#step' do
    it 'starts a stopped worker' do
      shell = Hive::Controller::Shell.new({'max_workers' => 1})
      shell.step
      expect(shell.instance_variable_get(:@workers)[0]).to be_a Hive::Worker::Shell
    end

    it 'starts multiple workers' do
      shell = Hive::Controller::Shell.new({'max_workers' => 3})
      shell.step
      expect(shell.instance_variable_get(:@workers).length).to be 3
    end

    it 'does not start a worker' do
      shell = Hive::Controller::Shell.new({'max_workers' => 0})
      shell.step
      expect(shell.instance_variable_get(:@workers).length).to be 0
    end

    it 'does not start an extra worker' do
      shell = Hive::Controller::Shell.new({'max_workers' => 1})
      shell.step
      shell.step
      expect(shell.instance_variable_get(:@workers).length).to be 1
    end
  end
end
