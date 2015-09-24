require 'hive'

module Hive
  # Generic hive controller class
  class Controller
    class DeviceDetectionFailed < StandardError
    end

    class NoPortsAvailable < StandardError
    end

    def initialize(config = {})
      @config = config
      @device_class = self.class.to_s.sub('Controller', 'Device')
      require @device_class.downcase.gsub(/::/, '/')
      Hive.logger.info("Controller '#{self.class}' created")

      @ports = (@config['minimum_port'].nil? or @config['maximum_port'].nil? ? [] : Array(@config['minimum_port']..@config['maximum_port']))
      @allocated_ports = []
    end

    def allocate_ports
      ps = []
      if ! @config['ports_allocate'].nil?
        if @config['ports_allocate'] > @ports.length
          raise NoPortsAvailable
        else
          ps = @ports.take(@config['ports_allocate'])
          @allocated_ports.concat(ps)
          @ports = @ports.drop(@config['ports_allocate'])
        end
      end
      Hive.logger.debug("Allocating ports: #{ps.inspect}")
      ps
    end

    def release_ports(ps)
      Hive.logger.debug("Releasing ports: #{ps}")
      ps.each do |p|
        @ports << p if @allocated_ports.delete(p)
      end
    end

    def create_device(extra_options = {})
      Object.const_get(@device_class).new(@config.merge(extra_options).merge('ports' => allocate_ports))
    end

    def detect
      raise NotImplementedError, "'detect' method not defined for '#{self.class}'"
    end
  end
end
