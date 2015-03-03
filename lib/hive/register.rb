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

    def instantiate_controllers(controller_details = Hive.config.controllers)
      controller_details.each do |type, opts|
        Hive.logger.info("Adding controller for '#{type}'")
        require "hive/controller/#{type}"
        controller = Object.const_get('Hive').const_get('Controller').const_get(type.capitalize).new(opts.to_hash)
        @controllers << controller
      end
      check_controllers
      @controllers
    end

    def run
      loop do
        Hive.poll
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
            new_device_list[c.class] << (i ? @devices[c.class][i] : device)
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
  end
end
