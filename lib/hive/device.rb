require 'hive'

module Hive
  # The generic device class
  class Device
    attr_reader :type
    attr_reader :pid

    # Initialise the device
    def initialize(options)
      @pid = nil
      @options = options
      @worker_class = self.class.to_s.sub('Device', 'Worker')
      require @worker_class.downcase.gsub(/::/, '/')
    end

    # Start the worker process
    def start
      parent_pid = Process.pid
      @pid = Process.fork do
        worker = Object.const_get(@worker_class).new(parent_pid, @options)
      end
      Process.detach @pid

      LOG.info("Worker started with pid #{@pid}")
    end

    # Terminate the worker process
    def stop
      Process.kill 'TERM', @pid
    end

    # Test the state of the worker process
    def running?
      begin
        Process.kill 0, @pid
        true
      rescue Errno::ESRCH
        false
      end
    end
  end
end
