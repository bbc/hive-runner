require 'spec_helper'
require 'hive/data_store'
require 'hive/data_store/port'
require 'timeout'

describe Hive::DataStore do

  describe '#assign' do
    before(:each) do
      @db_file = Tempfile.new('sqlite3')
      @ds = Hive::DataStore.new(@db_file.path)
    end

    after(:each) do
      @db_file.unlink
    end

    it 'allocates a port to a worker' do
      port = nil
      expect {
        port = Hive::DataStore::Port.assign('Worker-1')
      }.to change(Hive::DataStore::Port, :count).by(1)
      expect(port).to be_an Integer
      expect(port).to eq Hive::DataStore::Port.last.port
      expect(Hive::DataStore::Port.last.worker).to eq 'Worker-1'
    end

    it 'allocates different ports to two worker' do
      port1 = Hive::DataStore::Port.assign('Worker-1')

      port2 = nil
      expect {
        port2 = Hive::DataStore::Port.assign('Worker-2')
      }.to change(Hive::DataStore::Port, :count).by(1)
      expect(port2).to be_an Integer
      expect(port2).to_not eq port1
      expect(port2).to eq Hive::DataStore::Port.last.port
      expect(Hive::DataStore::Port.last.worker).to eq 'Worker-2'
    end

    it 'allocates 12 ports to 12 worker' do
      ports = []
      (1..12).each do |i|
        ports << Hive::DataStore::Port.assign("Worker-#{i}")
      end
      expect(ports.uniq.length).to be 12
    end

    it 'releases a port' do
      port = Hive::DataStore::Port.assign('Worker')

      expect {
        Hive::DataStore::Port.release(port)
      }.to change(Hive::DataStore::Port, :count).by(-1)
      expect(Hive::DataStore::Port.find_by(port: port)).to be_nil
    end

    it 'releases only the correct port' do
      port1 = Hive::DataStore::Port.assign('Worker')
      port2 = Hive::DataStore::Port.assign('Worker')

      expect {
        Hive::DataStore::Port.release(port2)
      }.to change(Hive::DataStore::Port, :count).by(-1)
      expect(Hive::DataStore::Port.find_by(port: port1)).to be_a(Hive::DataStore::Port)
      expect(Hive::DataStore::Port.find_by(port: port2)).to be nil
    end

    it 'raises a Hive::DataStore::Port::NoPortsAvailable exception' do
      # Use up all the port
      (Hive::DataStore::Port::MINIMUM_PORT..Hive::DataStore::Port::MAXIMUM_PORT).each do |i|
        Hive::DataStore::Port.assign('Worker')
      end

      begin
        Timeout.timeout(5) {
          expect {
            Hive::DataStore::Port.assign('Worker')
          }.to raise_error(Hive::DataStore::Port::NoPortsAvailable)
        }
      rescue => e
        raise e
      end
    end
  end
end
