require 'mono_logger'

module Hive
  # Hive logging
  # Allow logging to be written to multiple locations.
  class Log
    attr_accessor :hive_mind
    attr_accessor :default_progname

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

    # Currently this will clear the Hive Mind log but do nothing to the local
    # files
    def clear(component = nil, level = nil)
      if self.hive_mind
        self.hive_mind.clear_state component: component, level: level
      end
    end

    private
    def write_log(level, *args, &block)
      progname = ( block && args.length > 0 ) ? args[0] : @default_progname

      @loggers.each do |_s, l|
        l.send(level, progname) { block ? yield : args[0] }
      end

      if self.hive_mind
        params = {
          state: level,
          component: progname,
          message: block ? yield : args[0]
        }

        self.hive_mind.set_state params
      end
    end

  end
end
