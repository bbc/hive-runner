require 'spec_helper'

require 'hive/controller/test'

describe Hive::Controller do
  describe '#find_devices' do
    it 'find a new device' do
      shell = Hive::Controller::Test.new()
      devices = shell.find_devices(1)
      expect(devices.length).to be 1
      expect(devices[0]).to be_a Hive::Device::Test
    end

    it 'starts multiple workers' do
      shell = Hive::Controller::Test.new()
      devices = shell.find_devices(3)
      expect(devices.length).to be 3
      devices.each do |d|
        expect(d).to be_a Hive::Device::Test
      end
    end

    it 'does not start a worker' do
      shell = Hive::Controller::Test.new()
      devices = shell.find_devices(0)
      expect(devices.length).to be 0
    end
  end
end
