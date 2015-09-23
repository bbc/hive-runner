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

  describe '#clear_ports' do
    before(:each) do
      ENV['HIVE_ENVIRONMENT'] = 'test_daemon_helper_single_controller'
      load File.expand_path('../../../lib/hive.rb', __FILE__)
      register.instantiate_controllers
      @pids = register.worker_pids

      @file = Tempfile.new('ports')
      Hive.config.datastore.filename = @file.path
    end

    after(:each) do
      @file.unlink
      Hive.instance_variable_set(@data_store, nil)
    end

    it 'removes a port after the worker has terminated' do
      p = @pids[0]
      Hive.data_store.port.assign(p)
      Process.kill 'TERM', p
      sleep 2
      register.clear_ports
      expect(Hive.data_store.port.where(worker: p).length).to be 0
    end

    it 'does not remove a port from a worker that has not terminated' do
      p = @pids[0]
      port = Hive.data_store.port.assign(p)
      register.clear_ports
      expect(Hive.data_store.port.where(worker: p).first.port).to be port
    end

    it 'identifies correct ports to remove' do
      p1 = @pids[0]
      port1 = Hive.data_store.port.assign(p1)
      p2 = @pids[1]
      port2 = Hive.data_store.port.assign(p2)
      Process.kill 'TERM', p1
      sleep 2
      register.clear_ports
      list = Hive.data_store.port.all
      expect(list.length).to be 1
      expect(list.first.port).to be port2
    end
  end
end
