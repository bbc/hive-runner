require 'spec_helper'
require 'hive/register'

describe Hive::Register do
  describe '#instantiate_controllers' do
    it 'instantiates a test controller' do
      ENV['HIVE_ENVIRONMENT'] = 'test_daemon_helper_instantiate'
      load File.expand_path('../../../lib/hive.rb', __FILE__)
      Hive::Register.instantiate_controllers
      expect(Hive::Register.controllers[0]).to be_a Hive::Controller::Test
    end
  end

  describe '#workers' do
    it 'returns the list of workers from a single controller' do
      ENV['HIVE_ENVIRONMENT'] = 'test_daemon_helper_single_controller'
      load File.expand_path('../../../lib/hive.rb', __FILE__)
      Hive::Register.instantiate_controllers
      w = Hive::Register.workers
      expect(w).to be_an Array
      expect(w.length).to be 5
    end
  end
end
