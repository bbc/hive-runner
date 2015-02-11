require 'spec_helper'

require 'hive/device/shell'

describe Hive::Device::Shell do
  describe '#==' do
    it 'identifies two devices as the same' do
      expect(Hive::Device::Shell.new('id' => 1)).to eq Hive::Device::Shell.new('id' => 1)
    end

    it 'identifies two device as not the same' do
      expect(Hive::Device::Shell.new('id' => 1)).not_to eq Hive::Device::Shell.new('id' => 2)
    end
  end
end
