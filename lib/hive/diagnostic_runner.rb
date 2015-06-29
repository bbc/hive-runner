module Hive
	class Diagnostic_Runner
		
		def initialize(options, diagnostic_type)
			@diagnostic = []
			@options = options
			@diagnostic_type = diagnostic_type
			@diagnostic_array = Hive.config.diagnostic[@diagnostic_type].keys #read_config() # Read,  and store in array
        	initialize_diagnostic(Hive.config.diagnostic) # Use array to initialize objects + capitalize
	    	run_diagnostic unless !should_run?# Run method in subclasses calling base class method 	
    	end

    	def initialize_diagnostic(diagnostic_details)
      		@diagnostic_array.each { |component|
      			Hive.logger.info("Initializing #{component.capitalize} component for #{@diagnostic_type.capitalize} diagnostic")
        		require "hive/diagnostic/#{@diagnostic_type}/#{component}"
        		@diagnostic << Object.const_get('Hive').const_get('Diagnostic').const_get(@diagnostic_type.capitalize).const_get(component.capitalize).new(diagnostic_details[@diagnostic_type][component])
        		#@diagnostic << diagnostic
      		}
    	end 

    	def should_run?
    		return true
    	end

    	def run_diagnostic	
        	@diagnostic.each{ |diag|
        		diag.run(@options)
            	# Can catch result (like wifi => 'ok', memory => 'not ok') here and pass on to device db ? 
        	}

		end
	end
end