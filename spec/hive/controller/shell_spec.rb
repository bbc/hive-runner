require 'spec_helper'

require 'hive/controller/shell'

describe Hive::Controller::Shell do
  describe '#detect' do
    it 'find a single shell' do
      shell = Hive::Controller::Shell.new('workers' => 1)
      devices = shell.detect
      expect(devices.length).to be 1
      expect(devices[0]).to be_a Hive::Device::Shell
    end

    it 'find multiple shells' do
      shell = Hive::Controller::Shell.new('workers' => 3)
      devices = shell.detect
      expect(devices.length).to be 3
      devices.each do |d|
        expect(d).to be_a Hive::Device::Shell
      end
    end

    it 'does not start a shell' do
      shell = Hive::Controller::Shell.new('workers' => 0)
      devices = shell.detect
      expect(devices.length).to be 0
    end
  end
end
