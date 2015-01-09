require 'hive'
require 'daemons'

module Hive
  # The generic worker class
  class Worker
    attr_reader :type
    attr_reader :pid

    def initialize(options)
      @pid = Process.fork do
        pid = Process.pid
        $PROGRAM_NAME = "#{options['name_stub'] || 'WORKER'}.#{pid}"
        @log = Hive::Log.new
        @log.add_logger(
          "#{LOG_DIRECTORY}/#{pid}.log",
          CONFIG['logging']['worker_level'] || 'INFO'
        )

        worker_process
      end

      LOG.info("Worker started with pid #{@pid}")
    end

    def stop
      Process.kill('TERM', pid)
    end

    private

    def worker_process
      @log.info('Starting worker')
      loop do
        @log.info('In worker')
        sleep 5
      end
    end
  end
end
