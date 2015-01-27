require 'logger'

module Hive
  # Hive logging
  # Allow logging to be written to multiple locations.
  class Log
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
      log = Logger.new(stream)
      log.formatter = proc do |severity, datetime, _progname, msg|
        "#{severity[0, 1]} #{datetime.strftime('%Y-%m-%d %H:%M:%S')}: #{msg}\n"
      end
      log.level = Logger.const_get(level)
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

    Logger::Severity.constants.each do |level|
      define_method(level.downcase) do |*args|
        @loggers.each { |_s, l| l.send(level.downcase, *args) }
      end
    end
  end
end
