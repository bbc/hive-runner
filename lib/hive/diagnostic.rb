require 'hive'
require 'device_api/android'
require 'hive/results'
      
module Hive
  class Diagnostic
    
    class InvalidParameterError < StandardError
      end

    attr_accessor :config, :last_run, :device_api

    def initialize(config, options)
      @options = options
      @config = config
      @serial = @options['serial']
      @device_api = @options['device_api']
    end

    def should_run?
      return true if @last_run == nil
      time_now = Time.new.getutc
      last_run_time = @last_run.timestamp
      diff = ((time_now - last_run_time)/5.minutes).round
      if (diff > 2 && @last_run.passed?) || diff > 1
        true
      else
        false
      end
    end

    def run
      Hive.logger.info("Trying to run diagnostic '#{self.class}'")
      if should_run?  
        result = diagnose 
        result = repair(result) if result.failed?
        @last_run = result
      end
      @last_run 
    end

    def pass(message= {}, data = {})
      Hive.logger.info(message)
      Hive::Results.new("pass", message, data )
    end

    def fail(message ={}, data = {})
      Hive.logger.info(message)
      Hive::Results.new("fail", message, data)
    end
  end
end
