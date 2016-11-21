require 'mono_logger'

module Hive
  # Hive logging
  # Allow logging to be written to multiple locations.
  class Log
    attr_accessor :hive_mind

    # Create the logger:
    #
    #   # No log files will be written
    #   log = Hive::Log.new()
    #   # Write log files to standard out and a log file
    #   log = Hive::Log.new( [
    #                           {
    #                             stream: 'Filename.log',
    #                             level: 'DEBUG'
    #                           },
    #                           {
    #                             stream: STDOUT,
    #                             level: 'INFO'
    #                           },
    #                         ] )
    def initialize(args = [])
      @loggers = {}
      args.each do |l|
        add_logger(l[:stream], l[:level])
      end
    end

    # Add a new log location:
    #
    #   # INFO level log to 'Filename.log'
    #   log.add_logger( 'Filename.log', 'INFO' )
    #   # DEBUG level log to standard output
    #   log.add_logger( STDOUT, 'DEBUG' )
    def add_logger(stream, level)
      log = MonoLogger.new(stream)
      log.formatter = proc do |severity, datetime, progname, msg|
        "#{severity[0, 1]} #{datetime.strftime('%Y-%m-%d %H:%M:%S')} -- #{progname}: #{msg}\n"
      end
      log.level = MonoLogger.const_get(level)
      @loggers[stream] = log
    end

    # Stop a log stream:
    #
    #   # Stop the log to standard output
    #   log.stop_logger( STDOUT )
    #   # Stop the log to 'Filename.log'
    #   log.stop_logger( 'Filename.log' )
    def stop_logger(stream)
      @loggers.delete(stream)
    end

    # These methods were originally created using define_method as they are all
    # the same. However, blocks cannot be used with define_method.
    def debug(*args, &block)
      write_log('debug', *args, &block)
    end

    def info(*args, &block)
      write_log('info', *args, &block)
    end

    def warn(*args, &block)
      write_log('warn', *args, &block)
    end

    def error(*args, &block)
      write_log('error', *args, &block)
    end

    def fatal(*args, &block)
      write_log('fatal', *args, &block)
    end

    def unknown(*args, &block)
      write_log('unknown', *args, &block)
    end

    private
    def write_log(level, *args, &block)
      @loggers.each do |_s, l|
        if block
          l.send(level, *args) { yield }
        else
          l.send(level, *args)
        end
      end
      if self.hive_mind
        params = { state: level }
        if block
          params[:component] = args[0]
          params[:message] = yield
        else
          params[:message] = args[0]
        end

        self.hive_mind.set_state params
      end
    end

  end
end
