require 'hive'
require 'device_api/android'
module Hive
	class Diagnostic

		class DiagnosticFailed < StandardError
        end

		attr_accessor :options # should hold diagnostic criteria
    	#attr_accessor :device # device to run diagnostics on
 	
 		attr_accessor :timestamp
    	attr_accessor :status
    	attr_accessor :message

	 	def initialize(diagnostics_options)
 		  	@diagnostics_options = diagnostics_options
    	end
	
      	def run(options)
      		@options = options
      		require 'pry'
      		binding.pry
      			Hive.logger.info("Trying to run diagnostic '#{self.class}'")
      		component = self.class.to_s.scan(/[^:][^:]*/)[3].downcase	# should get it from @options
      		diagnostic_method = "check_"+"#{component}"
      		self.send(diagnostic_method) 
		end

      	def record_result(status,message)
        	self.status = status
        	self.message = message
        	self.timestamp = Time.now.getutc
      	end

      	def as_json
        	{ @name.to_sym => [ :timestamp => @timestamp, \
                            :status => @status, \
                            :message => @message] }.as_json
      	end
	end
end 