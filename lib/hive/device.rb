require 'hive'

module Hive
  # The generic device class
  class Device
    attr_reader :type
    attr_accessor :status
    attr_accessor :ports

    # Initialise the device
    def initialize(options)
      @worker_pid = nil
      @options = options
      @ports = options['ports'] or []
      @status = @options.has_key?('status') ? @options['status'] : 'none'
      @worker_class = self.class.to_s.sub('Device', 'Worker')
      require @worker_class.downcase.gsub(/::/, '/')
      raise ArgumentError, "Identity not set for #{self.class} device" if ! @identity
    end

    # Start the worker process
    def start
      parent_pid = Process.pid
      @worker_pid = Process.fork do
        worker = Object.const_get(@worker_class).new(@options.merge('parent_pid' => parent_pid, 'device_identity' => self.identity, 'ports' => self.ports))
      end
      Process.detach @worker_pid

      Hive.logger.info("Worker started with pid #{@worker_pid}")
    end

    # Terminate the worker process
    def stop
      begin
        count = 0
        while self.running? && count < 30 do
          count += 1
          Hive.logger.info("Attempting to terminate process #{@worker_pid} [#{count}]")
          Process.kill 'TERM', @worker_pid
          sleep 30
        end
        Process.kill 'KILL', @worker_pid if self.running?
      rescue => e
        Hive.logger.info("Process had already terminated")
      end
      @worker_pid = nil
    end

    # Test the state of the worker process
    def running?
      if @worker_pid
        begin
          Process.kill 0, @worker_pid
          true
        rescue Errno::ESRCH
          false
        end
      else
        false
      end
    end

    # Return the worker pid, checking to see if it is running first
    def worker_pid
      @worker_pid = nil if ! self.running?
      @worker_pid
    end

    # Return true if the device is claimed
    # If the device has no status set it is assumed not to be claimed
    def claimed?
      @status == 'claimed'
    end

    # Test equality with another device
    def ==(other)
      self.identity == other.identity
    end

    # Return the unique identity of the device
    def identity
      "#{self.class.to_s.split('::').last}-#{@identity}"
    end
  end
end
