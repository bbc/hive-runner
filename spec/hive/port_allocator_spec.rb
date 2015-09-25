require 'spec_helper'
require 'hive/port_allocator'

RSpec.describe Hive::PortAllocator do
  describe '.new' do
    it 'creates a Hive::PortAllocator based on minimum and maximum port' do
      expect(Hive::PortAllocator.new(minimum: 500, maximum: 600)).to be_a(Hive::PortAllocator)
    end

    it 'creates a Hive::PortAllocator based on an array of integers' do
      expect(Hive::PortAllocator.new(ports: [1, 2, 3, 4, 5])).to be_a(Hive::PortAllocator)
    end

    it 'creates a Hive::PortAllocator with a single port range' do
      expect(Hive::PortAllocator.new(minimum: 500, maximum: 500)).to be_a(Hive::PortAllocator)
    end

    context 'creation ports range' do
      it 'fails with missing minimum port' do
        expect{Hive::PortAllocator.new(maximum: 600)}.to raise_error(ArgumentError)
      end

      it 'fails with missing maximum port' do
        expect{Hive::PortAllocator.new(minimum: 500)}.to raise_error(ArgumentError)
      end

      it 'fails with with maximum port lower than minimum port' do
        expect{Hive::PortAllocator.new(minimum: 500, maximum: 400)}.to raise_error(ArgumentError)
      end

      it 'fails when minimum port is not positive' do
        expect{Hive::PortAllocator.new(minimum: 0, maximum: 400)}.to raise_error(ArgumentError)
        expect{Hive::PortAllocator.new(minimum: -100, maximum: 400)}.to raise_error(ArgumentError)
      end
    end

    context 'creation with ports array' do
      it 'fails when ports is not an array' do
        expect{Hive::PortAllocator.new(ports: 500)}.to raise_error(ArgumentError)
      end

      it 'fails when ports contains non-positive integers' do
        expect{Hive::PortAllocator.new(ports: [0, 1, 2, 3, 4])}.to raise_error(ArgumentError)
        expect{Hive::PortAllocator.new(ports: [1, 2, -3, 4, 5])}.to raise_error(ArgumentError)
        expect{Hive::PortAllocator.new(ports: [1, 2, 3, 'four', 5])}.to raise_error(ArgumentError)
      end
    end
  end

  context 'individual port allocation' do
    let(:one_port) { Hive::PortAllocator.new(minimum: 500, maximum: 500) }
    let(:fifty_ports) { Hive::PortAllocator.new(minimum: 501, maximum: 550) }

    describe '#allocate_port' do
      it 'allocates a single port' do
        expect(one_port.allocate_port).to eq 500
      end

      it 'allocates multiple ports in the given range' do
        50.times do
          expect(fifty_ports.allocate_port).to be_between(501, 550)
        end
      end

      it 'allocates different ports' do
        p = fifty_ports.allocate_port
        expect(fifty_ports.allocate_port).to_not eq p
      end

      it 'fails when no ports are available' do
        one_port.allocate_port
        expect{one_port.allocate_port}.to raise_error(Hive::PortAllocator::NoPortsAvailable)
      end
    end

    describe '#release_port' do
      it 'allows a released port to be reallocated' do
        p = one_port.allocate_port
        one_port.release_port(p)
        expect(one_port.allocate_port).to eq p
      end

      it 'does not release an unknown port' do
        p = one_port.allocate_port
        one_port.release_port(501)
        expect{one_port.allocate_port}.to raise_error(Hive::PortAllocator::NoPortsAvailable)
      end
    end
  end

  context 'subranges' do
    let(:one_port) { Hive::PortAllocator.new(ports: [500]) }
    let(:fifty_ports) { Hive::PortAllocator.new(minimum: 501, maximum: 550) }

    describe '#allocate_port_range' do
      it 'creates a Hive::PortAllocator instance' do
        expect(fifty_ports.allocate_port_range(5)).to be_a Hive::PortAllocator
      end

      it 'creates a valid subrange' do
        sr = fifty_ports.allocate_port_range(5)
        5.times do
          expect(sr.allocate_port).to be_between(501, 550)
        end
        expect{sr.allocate_port}.to raise_error(Hive::PortAllocator::NoPortsAvailable)
      end

      it 'fails if sufficient ports are unavailable' do
        expect{fifty_ports.allocate_port_range(51)}.to raise_error(Hive::PortAllocator::NoPortsAvailable)

      end

      it 'creates distinct subranges' do
        sr1 = fifty_ports.allocate_port_range(5)
        sr2 = fifty_ports.allocate_port_range(5)
        list1 = []
        list2 = []
        5.times { list1 << sr1.allocate_port }
        5.times { list2 << sr2.allocate_port }
        expect(list1 & list2).to eq []
      end
    end

    describe '#release_port_range' do
      it 'releases a port range' do
        sr = fifty_ports.allocate_port_range(50)
        fifty_ports.release_port_range(sr)
        expect(fifty_ports.allocate_port).to be_between(501, 550)
      end

      it 'does not release if any ports are unknown' do
        sr = fifty_ports.allocate_port_range(50)
        fifty_ports.release_port_range(one_port)
        expect{fifty_ports.allocate_port}.to raise_error(Hive::PortAllocator::NoPortsAvailable)
      end

      it 'allows a released range to be reallocated' do
        sr1 = fifty_ports.allocate_port_range(50)
        fifty_ports.release_port_range(sr1)
        sr2 = fifty_ports.allocate_port_range(50)
        50.times do
          expect(sr2.allocate_port).to be_between(501, 550)
        end
      end
    end
  end

  describe '#release_all_ports' do
    let(:fifty_ports) { Hive::PortAllocator.new(minimum: 501, maximum: 550) }

    it 'releases all individually allocated ports' do
      fifty_ports.allocate_port
      fifty_ports.allocate_port
      fifty_ports.allocate_port
      fifty_ports.release_all_ports

      50.times do
        expect(fifty_ports.allocate_port).to be_between(501, 550)
      end
    end

    it 'releases all allocated port ranges' do
      fifty_ports.allocate_port_range(5)
      fifty_ports.allocate_port_range(10)
      fifty_ports.allocate_port_range(15)
      fifty_ports.release_all_ports

      50.times do
        expect(fifty_ports.allocate_port).to be_between(501, 550)
      end
    end

    it 'releases all ports allocated individually or as ranges' do
      fifty_ports.allocate_port_range(5)
      fifty_ports.allocate_port
      fifty_ports.allocate_port_range(15)
      fifty_ports.release_all_ports

      50.times do
        expect(fifty_ports.allocate_port).to be_between(501, 550)
      end
    end
  end

  describe 'empty allocators' do
    it 'creates an empty allocator' do
      expect(Hive::PortAllocator.new(ports: [])).to be_a Hive::PortAllocator
    end

    it 'allocates an empty subrange' do
      pa = Hive::PortAllocator.new(minimum: 500, maximum: 600)
      expect(pa.allocate_port_range(0)).to be_a Hive::PortAllocator
    end

    it 'allocates an empty subrange of an empty allocator' do
      pa = Hive::PortAllocator.new(ports: [])
      expect(pa.allocate_port_range(0)).to be_a Hive::PortAllocator
    end
  end
end
