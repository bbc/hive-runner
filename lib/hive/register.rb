require 'hive'

module Hive
  # Central register of devices and workers in the hive
  module Register
    @controllers = []
    @workers = []
    @max_devices = 5 # TODO Add to configuration file

    def self.controllers
      @controllers
    end

    def self.workers
      @workers
    end

    def self.instantiate_controllers(controller_details = Chamber.env.controllers)
      controller_details.each do |type, opts|
        LOG.info("Adding controller for '#{type}'")
        require "hive/controller/#{type}"
        controller = Object.const_get('Hive').const_get('Controller').const_get(type.capitalize).new(opts)
        @workers.concat(controller.find_devices(@max_devices - @workers.length))
        @controllers << controller
      end
      @controllers
    end

    def self.run
      loop do
        @controllers.each do |c|
          @workers.concat(c.find_devices(@max_devices - @workers.length))
          sleep Chamber.env.timings.controller_loop_interval
        end
        @workers.each do |w|
          w.start if ! w.running?
        end
      end
    end
  end
end
