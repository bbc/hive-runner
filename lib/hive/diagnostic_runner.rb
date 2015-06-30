module Hive
	class Diagnostic_Runner
		
		def initialize(options, diagnostic_type)
			@diagnostic = []
			@options = options
			@diagnostic_type = diagnostic_type
			@diagnostic_array = Hive.config.diagnostic[@diagnostic_type].keys 
        	initialize_diagnostic(Hive.config.diagnostic) 
        	run_diagnostic unless !should_run? 	
    	end

    	def initialize_diagnostic(diagnostic_details)
      		@diagnostic_array.each { |component|
      			Hive.logger.info("Initializing #{component.capitalize} component for #{@diagnostic_type.capitalize} diagnostic")
        		require "hive/diagnostic/#{@diagnostic_type}/#{component}"
        		@diagnostic << Object.const_get('Hive').const_get('Diagnostic').const_get(@diagnostic_type.capitalize).const_get(component.capitalize).new(diagnostic_details[@diagnostic_type][component])
        	}
    	end 

    	def should_run?
    		 # 	previous_timestamp = "2015-06-29 14:39:05 +UTC" # get_prev_timestamp
    			# current_timestamp = Time.new.getutc
    			# return ((current_timestamp - previous_timestamp)/30.minutes).round > 0 ? true : false
    			# # previous_timestamp ==> write method to get timestamp from db for particular device
    		return true
    	end

    	def run_diagnostic	
        	@diagnostic.each{ |diag|
        		diag.run(@options) 
           }
		end

		def repair
				# Should be either called from here or from within diagnostic ? 
		end
	end
end