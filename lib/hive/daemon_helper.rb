require 'hive'

module Hive
  # Helper functions for the Hive Daemon
  module DaemonHelper
    @controllers = []

    def self.controllers
      @controllers
    end

    def self.instantiate_controllers(controller_details = Hive::CONFIG['controllers'])
      controller_details.each do |type, opts|
        require "hive/controller/#{type}"
        @controllers << Object.const_get('Hive').const_get('Controller').const_get(type.capitalize).new(opts)
      end
      @controllers
    end

    def self.run
      loop do
        @controllers.each do |c|
          c.step
        end
        sleep 5
      end
    end
  end
end
