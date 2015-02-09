require 'hive'

module Hive
  # Generic hive controller class
  class Controller
    def initialize(config = {})
      @config = config
      @device_class = self.class.to_s.sub('Controller', 'Device')
      require @device_class.downcase.gsub(/::/, '/')
    end

    def find_devices(number)
      (1..number).collect do
        Object.const_get(@device_class).new(@config)
      end
    end
  end
end
