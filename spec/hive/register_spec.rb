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

    xit "allows one controller's devices to update if another fails" do
      controller_list = {}
      register.controllers.each do |c|
        controller_list[c.class] = c
      end
      controller_list[Hive::Controller::Test].detect_success = false
      controller_list[Hive::Controller::Shell].instance_variable_set(:@workers, 2)
      register.check_controllers
      expect(register.devices.length).to be 7
    end
  end

  describe '#clear_workspaces' do
    before(:each) do
      @dir = Dir.mktmpdir
      Hive.config.logging.home = @dir
    end

    after(:each) do
      FileUtils.remove_dir(@dir)
    end

    it 'does to crash with no workspaces' do
      expect{register.clear_workspaces}.to_not raise_error
    end

    it 'leaves the required number of completed workspaces' do
      (1..5).each do |i|
        Dir.mkdir("#{@dir}/#{i}")
        File.open("#{@dir}/#{i}/job_info", 'w') do |f|
          f.puts '12345 completed'
        end
      end

      register.clear_workspaces
      expect(Dir.entries(@dir).select {|entry| File.directory? File.join(@dir, entry) and !(entry =='.' || entry == '..') }.length).to be 5
    end

    it 'leaves the required number of completed workspaces' do
      (1..6).each do |i|
        Dir.mkdir("#{@dir}/#{i}")
        File.open("#{@dir}/#{i}/job_info", 'w') do |f|
          f.puts '12345 completed'
        end
      end

      register.clear_workspaces
      expect(Dir.entries(@dir).select {|entry| File.directory? File.join(@dir, entry) and !(entry =='.' || entry == '..') }.length).to be 5
    end

    it 'does not remove workspaces for running jobs' do
      (1..6).each do |i|
        Dir.mkdir("#{@dir}/#{i}")
        File.open("#{@dir}/#{i}/job_info", 'w') do |f|
          f.puts '12345 running'
        end
      end

      register.clear_workspaces
      expect(Dir.entries(@dir).select {|entry| File.directory? File.join(@dir, entry) and !(entry =='.' || entry == '..') }.length).to be 6
    end
  end

  describe '#worker_pids' do
    it 'returns an empty array for no workers' do
      expect(register.worker_pids).to eq []
    end

    it 'returns a list of 5 pids for the workers of 5 devices' do
      ENV['HIVE_ENVIRONMENT'] = 'test_daemon_helper_single_controller'
      load File.expand_path('../../../lib/hive.rb', __FILE__)
      register.instantiate_controllers
      p = register.worker_pids
      expect(p).to be_an Array
      expect(p.length).to be 5
    end

    it 'updates the pid list after a worker terminates' do
      ENV['HIVE_ENVIRONMENT'] = 'test_daemon_helper_single_controller'
      load File.expand_path('../../../lib/hive.rb', __FILE__)
      register.instantiate_controllers
      Process.kill 'TERM', register.worker_pids[0]
      sleep 2
      p = register.worker_pids
      expect(p).to be_an Array
      expect(p.length).to be 4
    end
  end
end
