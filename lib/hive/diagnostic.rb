require 'hive'
require 'device_api/android'
module Hive
	class Diagnostic

		class DiagnosticFailed < StandardError
		end

		attr_accessor :options 
 		attr_accessor :timestamp
 		attr_accessor :device
 		attr_accessor :component
		attr_accessor :status
		attr_accessor :message

	 	def initialize(diagnose_criteria)
 		  	@criteria = diagnose_criteria
		end
	
    	def run(options)
      		@options = options
      		Hive.logger.info("Trying to run diagnostic '#{self.class}'")
      		component = self.class.to_s.scan(/[^:][^:]*/)[3].downcase	
      		diagnostic_method = "check_"+"#{component}"
      		self.send(diagnostic_method) 
      		#return {component => self.send(diagnostic_method)}
		end

		def should_run?
			true
		end

    	def record_result(component, status, message)
      		@component = component
        	@status = status
        	@message = message
        	@timestamp = Time.now.getutc
    	end

    	def as_json
        	{ @name.to_sym => [ :timestamp => @timestamp, \
        					:device => @options['serial'], \
        					:component => @component, \
                        	:status => @status, \
                        	:message => @message] }.as_json
		end
	end
end 