require 'hive/device'

module Hive
  # The generic device class
  class Windevice < Device
    attr_accessor :threads
    def initialize(options)
      super(options)
      @threads = []
    end

    def start
      object = Object
      @worker_class.split('::').each{ |sub| object = object.const_get(sub)}
      if @threads.count < 1
        @threads << Thread.new { object.new(@options.merge('device_identity' => self.identity, 'port_allocator' => self.port_allocator, 'hive_id' => Hive.hive_mind.device_details['id'])) }
        Hive.logger.info("Worker started in new thread #{@threads}")
      end
    end

    def stop
      begin
        while self.running? 
	  Hive.logger.info("Attempting to terminate thread #{@threads}")
	  @threads.first.kill
          @threads = []
        end
      rescue => e
        Hive.logger.info("Thread already terminated")
      end
      @threads = []
    end

    def running?
      if @threads.count > 0
          true
      else
        false
      end
    end


  end
end
