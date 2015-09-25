require 'hive'

module Hive
  # Generic hive controller class
  class Controller
    attr_reader :port_range_size

    class DeviceDetectionFailed < StandardError
    end

    class NoPortsAvailable < StandardError
    end

    def initialize(config = {})
      @config = config
      @device_class = self.class.to_s.sub('Controller', 'Device')
      require @device_class.downcase.gsub(/::/, '/')
      Hive.logger.info("Controller '#{self.class}' created")
      @port_range_size = (@config.has_key?('port_range_size') ? @config['port_range_size'] : 0)
    end

    def create_device(extra_options = {})
      Object.const_get(@device_class).new(@config.merge(extra_options))
    end

    def detect
      raise NotImplementedError, "'detect' method not defined for '#{self.class}'"
    end
  end
end
