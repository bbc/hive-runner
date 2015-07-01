require 'hive'
require 'device_api/android'
module Hive
	class Diagnostic
		class DiagnosticFailed < StandardError
		end

		attr_accessor :config 
		attr_accessor :last_run # => last Result object
		attr_accessor :status
		attr_accessor :message

	 	def initialize(config)
			@config = config
		end
	
		def run
			Hive.logger.info("Trying to run diagnostic '#{self.class}'")
			if should_run?
		    result = diagnose
		    result = repair(result) if result.failed?
		    last_run = result
		  end
		  last_run
	  end
	  
	  def should_run?
	    true
	  end
	  
	  def diagnose
	    Diagnostic::Result.new
	  end
	  
	  def repair(result)
	    result
	  end

	end
end 
