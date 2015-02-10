require 'hive'

module Hive
  # Central register of devices and workers in the hive
  class Register
    attr_reader :controllers
    attr_reader :devices

    def initialize
      @controllers = []
      @devices = []
      @max_devices = 5 # TODO Add to configuration file
    end

    #def controllers
    #  @controllers
    #end

    #def devices
    #  #Hive.logger.info("XXX Devices: #{@@devices.inspect}")
    #  @devices
    #end

    def instantiate_controllers(controller_details = Chamber.env.controllers)
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
        check_controllers
        sleep Chamber.env.timings.controller_loop_interval
      end
    end

    def check_controllers
      Hive.logger.debug("Devices before update: #{@devices.inspect}")
      new_device_list = []
      @controllers.each do |c|
        Hive.logger.info("Checking controller #{c.class}")
        c.detect.each do |device|
          Hive.logger.info("Found #{device.inspect}")
          i = @devices.find_index(device)
          new_device_list << (i ? @devices[i] : device)
        end
        Hive.logger.info("new_device_list: #{new_device_list.inspect}")
      end

      # Remove any devices that have not been rediscovered
      (@devices - new_device_list).each do |d|
        d.stop
        @devices.delete(d)
      end

      # Add any new devices
      (new_device_list - @devices).each do |d|
        @devices << d
      end

      # Check that all known devices have running workers
      @devices.each do |d|
        d.start if ! d.running?
      end
      Hive.logger.debug("Devices after update: #{@devices.inspect}")
    end
  end
end
