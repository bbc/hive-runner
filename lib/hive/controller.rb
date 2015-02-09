require 'hive'

module Hive
  # Generic hive controller class
  class Controller
    attr_reader :workers

    def initialize(config)
      @config = {
        'max_workers' => 0
      }.merge(config)
      @workers = []
      @device_class = self.class.to_s.sub('Controller', 'Device')
      require @device_class.downcase.gsub(/::/, '/')
    end

    def check_workers
      (1..(@config['max_workers'] - @workers.length)).each do
        device = Object.const_get(@device_class).new(@config)
        device.start
        @workers << device
      end
    end
  end
end
