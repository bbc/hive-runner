require 'hive'

module Hive
  # Central register of devices and workers in the hive
  class Register
    attr_reader :devices

    def initialize
      @controllers = []
      @devices = []
      @max_devices = 5 # TODO Add to configuration file
    end

    def controllers
      @controllers
    end

    #def devices
    #  Hive.logger.info("XXX Devices: #{@@devices.inspect}")
    #  @@devices
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
#        new_device_list = []
#        @controllers.each do |c|
#          Hive.logger.info("Checking controller #{c.class}")
#          c.detect.each do |device|
#            Hive.logger.info("Found #{device.inspect}")
#            i = @@devices.find_index(device)
#            new_device_list << (i ? @@devices.delete_at(i) : device)
#          end
#          sleep Chamber.env.timings.controller_loop_interval
#        end
#
#        # Any devices left in the @devices list were not found to be connected
#        @@devices.each { |d| d.stop }
#        @@devices = new_device_list
#
#        Hive.logger.info("Devices: #{@@devices.inspect}")
#
#        @@devices.each do |d|
#          d.start if ! d.running?
#        end
        check_controllers
      end
    end

    def check_controllers
      Hive.logger.info("Pid: #{Process.pid}")
      Hive.logger.info("Devices before: #{@devices.inspect}")
      new_device_list = []
      @controllers.each do |c|
        Hive.logger.info("Checking controller #{c.class}")
        c.detect.each do |device|
          Hive.logger.info("Found #{device.inspect}")
          i = @devices.find_index(device)
          new_device_list << (i ? @devices.delete_at(i) : device)
        end
        Hive.logger.info("new_device_list: #{new_device_list.inspect}")
        sleep Chamber.env.timings.controller_loop_interval
      end

      # Any devices left in the @devices list were not found to be connected
      @devices.each { |d| d.stop }
      @devices = new_device_list

      Hive.logger.info("Devices after: #{@devices.inspect}")

      @devices.each do |d|
        d.start if ! d.running?
      end
    end
  end
end
