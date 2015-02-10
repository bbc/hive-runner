require 'hive'

module Hive
  # Generic hive controller class
  class Controller
    def initialize(config = {})
      @config = config
      @device_class = self.class.to_s.sub('Controller', 'Device')
      require @device_class.downcase.gsub(/::/, '/')
      Hive.logger.info("Controller '#{self.class}' created")
    end

    def detect
      raise NotImplementedError, "'detect' method not defined for '#{self.class}'"
    end
  end
end
