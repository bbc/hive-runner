require 'spec_helper'

require 'hive/worker/shell'

describe Hive::Worker::Shell do
  context 'ports' do
    let(:port_list) { [4001, 4002, 4003, 4004, 4005] }
    let(:worker) { Hive::Worker::Shell.new('ports' => port_list) }
    let(:worker_one_port) { Hive::Worker::Shell.new('ports' => [4000]) }
    let(:worker_no_ports) { Hive::Worker::Shell.new }

    describe '#allocate_port' do
      it 'allocates a port' do
        expect(worker.allocate_port).to be_an(Integer)
      end

      it 'allocates a port in the range' do
        p = worker.allocate_port
        expect(port_list).to include(p)
      end

      it 'allocates two different ports' do
        p = worker.allocate_port
        expect(worker.allocate_port).to_not eq p
      end

      it 'fails to allocate a port with no range' do
        expect{worker_no_ports.allocate_port}.to raise_error(Hive::Worker::NoPortsAvailable)
      end

      it 'fails to allocate a port after all ports are allocated' do
        5.times { worker.allocate_port }
        expect{worker.allocate_port}.to raise_error(Hive::Worker::NoPortsAvailable)
      end
    end

    describe '#release_port' do
      it 'reallocates a released port' do
        p = worker_one_port.allocate_port
        worker_one_port.release_port(p)
        expect(worker_one_port.allocate_port).to eq p
      end

      it 'does not release an unknown port' do
        worker_no_ports.release_port(9999)
        expect{worker_no_ports.allocate_port}.to raise_error(Hive::Worker::NoPortsAvailable)
      end
    end

    describe '#release_all_ports' do
      it 'releases all ports' do
        5.times { worker.allocate_port }
        worker.release_all_ports
        p = worker.allocate_port
        expect(port_list).to include(p)
      end
    end
  end
end
