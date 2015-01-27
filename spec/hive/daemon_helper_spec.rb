require 'spec_helper'

require 'hive/daemon_helper'

describe Hive::DaemonHelper do
  describe '#instantiate_controllers' do
    it 'instantiates a test controller' do
      Hive::CONFIG['controllers'] = {
        'test' => {
          arg1: 'value',
          arg2: 'value2'
        }
      }
      Hive::DaemonHelper.instantiate_controllers
      expect(Hive::DaemonHelper.controllers[0]).to be_a Hive::Controller::Test
    end
  end

  describe '#workers' do
    it 'returns the list of workers from a single controller' do
      Hive::CONFIG['controllers'] = {
        'test' => {
          'max_workers' => 5
        }
      }
      Hive::DaemonHelper.instantiate_controllers
      w = Hive::DaemonHelper.workers
      expect(w).to be_an Array
      expect(w.length).to be 5
    end
  end
end
