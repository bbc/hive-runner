require 'hive'

module Hive
  # Central register of devices and workers in the hive
  class Register
    attr_reader :controllers

    def initialize
      @controllers = []
      @devices = {}
      @max_devices = 5 # TODO Add to configuration file
    end

    def devices
      list = []
      @devices.each do |controller, device_list|
        list.concat(device_list)
      end
      list
    end

    def worker_pids
      self.devices.collect{ |d| d.worker_pid }.compact
    end

    def instantiate_controllers(controller_details = Hive.config.controllers)
      controller_details.each do |type, opts|
        Hive.logger.info("Adding controller for '#{type}'")
        require "hive/controller/#{type}"
        controller = Object.const_get('Hive').const_get('Controller').const_get(type.capitalize).new(opts.to_hash)
        # require 'pry'
        # binding.pry
        @controllers << controller
      end
      check_controllers
      @controllers
    end

    def run
      loop do
        Hive.poll
        housekeeping
        check_controllers
        sleep Hive.config.timings.controller_loop_interval
      end
    end

    def check_controllers
      Hive.logger.debug("Devices before update: #{@devices.inspect}")
      new_device_list = {}
      @controllers.each do |c|
        begin
          new_device_list[c.class] = []
          @devices[c.class] = [] if ! @devices.has_key?(c.class)
          Hive.logger.info("Checking controller #{c.class}")
          c.detect.each do |device|
            Hive.logger.debug("Found #{device.inspect}")
            i = @devices[c.class].find_index(device)
            if i
              @devices[c.class][i].status = device.status
              new_device_list[c.class] << @devices[c.class][i]
            else
              new_device_list[c.class] << device
            end
          end
          Hive.logger.debug("new_device_list: #{new_device_list.inspect}")

          # Remove any devices that have not been rediscovered
          (@devices[c.class] - new_device_list[c.class]).each do |d|
            d.stop
            @devices[c.class].delete(d)
          end

          # Add any new devices
          (new_device_list[c.class] - @devices[c.class]).each do |d|
            @devices[c.class] << d
          end
          # Check that all known devices have running workers
          @devices[c.class].each do |d|
            if d.claimed?
              d.stop if d.running?
            else
              d.start if ! d.running?
            end
          end
        rescue Hive::Controller::DeviceDetectionFailed
          Hive.logger.warn("Failed to detect devices for #{c.class}")
        end
      end
      Hive.logger.debug("Devices after update: #{@devices.inspect}")
    end

    def housekeeping
      clear_workspaces
    end

    def clear_workspaces
      candidates = Dir.glob("#{Hive.config.logging.home}/*")
        .select{ |f|
          File.directory?(f) \
          && File.exists?("#{f}/job_info") \
          && File.read("#{f}/job_info").chomp.to_s =~ /completed/
        }.sort_by{ |f|
          File.mtime(f)
        }.reverse
      if candidates && candidates.length > Hive.config.logging.homes_to_keep
        candidates[Hive.config.logging.homes_to_keep..-1].each do |dir|
          Hive.logger.info("Found (and deleting) #{dir}")
          FileUtils.rm_rf(dir)
        end
      end
    end

    def clear_ports
      pids = self.worker_pids
      Hive.data_store.port.all.each do |p|
        p.delete if ! pids.include?(p.worker.to_i)
      end
    end
  end
end
