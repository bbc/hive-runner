require 'spec_helper'

require 'hive/controller'

describe Hive::Controller do
  context 'ports' do
    let(:controller) { Hive::Controller.new(
                         'minimum_port' => 10001,
                         'maximum_port' => 10050,
                         'ports_allocate' => 5
                       )
                     }
    let(:controller_no_ports) { Hive::Controller.new() }

    describe '#allocate_ports' do
      it 'creates a port range within the range' do
        r = controller.allocate_ports
        expect(r.length).to eq 5
        r.each do |p|
          expect(p).to be_between(10001, 10050).inclusive
        end
      end

      it 'creates two distinct port ranges within the range' do
        r1 = controller.allocate_ports
        r2 = controller.allocate_ports
        expect(r1.length).to eq 5
        expect(r2.length).to eq 5
        expect(r1 & r2).to eq []
      end

      it 'returns an empty array with no port configuration' do
        expect(controller_no_ports.allocate_ports.length).to eq 0
      end

      it 'fails if ports have run out' do
        10.times { controller.allocate_ports }
        expect{controller.allocate_ports}.to raise_error(Hive::Controller::NoPortsAvailable)
      end
    end

    describe '#release_ports' do
      it 'releases ports' do
        ps = controller.allocate_ports
        9.times { controller.allocate_ports }
        controller.release_ports(ps)
        expect(controller.allocate_ports).to match_array ps
      end

      it 'does not release unknown ports' do
        controller_no_ports.release_ports([9999])
        expect(controller_no_ports.allocate_ports).to eq []
      end
    end
  end
end
