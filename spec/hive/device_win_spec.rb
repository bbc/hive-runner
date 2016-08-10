require 'spec_helper'

# Using Hive::Device::Shell as a Hive::Device cannot be started on its own
require 'hive/device/shell'

describe Hive::Device do
  attr_accessor :device
  after(:each) do
     `FOR /f "tokens=2 delims= " %%i IN ('TASKLIST ^| FINDSTR "ruby"') DO taskkill /PID %%i /F`
  end

  before(:each) do
    @device = Hive::Device::Shell.new({'id' => 1})
  end

  describe '#start' do
    it 'Start test worker in thread' do
      @device.start
      expect(@device.threads.count).to be 1
    end
  end

  describe '#running?' do
    it 'shows that a worker is running' do
      @device.start
      expect(@device.running?).to be true
    end

    it 'shows that a worker is not running' do
      @device.stop
      sleep 1
      expect(@device.running?).to be false
    end
  end

  describe '#stop' do
    it 'terminates a test worker' do
      @device.start
      @device.stop
      expect(@device.threads.count).to be 0
    end
  end

end
