require 'spec_helper'

require 'hive/worker/shell'

module Hive
  class DataStore
    def initialize(config)
    end

    class Port
      def self.assign(worker)
        if @p.nil?
          @p = 4000
        else
          @p += 1
        end
      end
    end
  end
end

describe Hive::Worker::Shell do
  describe '#initialize' do
    it 'registers a port' do
      Hive.data_store.port.instance_variable_set(:@p, 3999)
      expect(Hive::Worker::Shell.new('ports' => ['port1']).instance_variable_get(:@ports)).to match({'port1' => 4000})
    end

    it 'registers two ports' do
      Hive.data_store.port.instance_variable_set(:@p, 3999)
      expect(Hive::Worker::Shell.new('ports' => ['port1', 'port2']).instance_variable_get(:@ports)).to match({'port1' => 4000, 'port2' => 4001})
    end
  end
end
