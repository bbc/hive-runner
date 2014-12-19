require 'spec_helper'

require 'hive/daemon_helper'

describe Hive::DaemonHelper do
  describe '#instantiate_controllers' do
    it 'instantiates a shell controller' do
      Hive::CONFIG['controllers'] = {
        'shell' => {
          arg1: 'value',
          arg2: 'value2'
        }
      }
      Hive::DaemonHelper.instantiate_controllers
      expect(Hive::DaemonHelper.controllers[0]).to be_a Hive::Controller::Shell
    end
  end
end
