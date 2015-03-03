require 'spec_helper'
require 'hive/register'

describe Hive::Register do
  let(:register) { Hive::Register.new }

  describe '#instantiate_controllers' do
    it 'instantiates a test controller' do
      ENV['HIVE_ENVIRONMENT'] = 'test_daemon_helper_instantiate'
      load File.expand_path('../../../lib/hive.rb', __FILE__)
      register.instantiate_controllers
      expect(register.controllers[0]).to be_a Hive::Controller::Shell
    end
  end

  describe '#devices' do
    it 'returns the list of devices from a single controller' do
      ENV['HIVE_ENVIRONMENT'] = 'test_daemon_helper_single_controller'
      load File.expand_path('../../../lib/hive.rb', __FILE__)
      register.instantiate_controllers
      d = register.devices
      expect(d).to be_an Array
      expect(d.length).to be 5
    end
  end

  describe '#check_controllers' do
    before(:each) do
      ENV['HIVE_ENVIRONMENT'] = 'test_daemon_helper_two_controllers'
      load File.expand_path('../../../lib/hive.rb', __FILE__)
      register.instantiate_controllers
    end

    it 'does not remove devices if device detect fails' do
      controller_list = {}
      register.controllers.each do |c|
        controller_list[c.class] = c
      end
      controller_list[Hive::Controller::Test].detect_success = false
      register.check_controllers
      expect(register.devices.length).to be 10 # 5 for each controller
    end

    it "allows one controller's devices to update if another fails" do
      controller_list = {}
      register.controllers.each do |c|
        controller_list[c.class] = c
      end
      controller_list[Hive::Controller::Test].detect_success = false
      controller_list[Hive::Controller::Shell].instance_variable_set(:@maximum, 2)
      register.check_controllers
      expect(register.devices.length).to be 7
    end
  end
end
