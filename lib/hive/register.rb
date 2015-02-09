require 'hive'

module Hive
  # Central register of devices and workers in the hive
  module Register
    @controllers = []

    def self.controllers
      @controllers
    end

    def self.workers
      workers = []
      @controllers.each do |c|
        workers.concat(c.workers)
      end
      workers
    end

    def self.instantiate_controllers(controller_details = Chamber.env.controllers)
      controller_details.each do |type, opts|
        LOG.info("Adding controller for '#{type}'")
        require "hive/controller/#{type}"
        controller = Object.const_get('Hive').const_get('Controller').const_get(type.capitalize).new(opts)
        controller.check_workers
        @controllers << controller
      end
      @controllers
    end

    def self.run
      loop do
        @controllers.each do |c|
          c.check_workers
          sleep Chamber.env.timings.controller_loop_interval
        end
      end
    end
  end
end
