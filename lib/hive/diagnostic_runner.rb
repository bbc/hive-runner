module Hive
	class DiagnosticRunner
			
		def initialize(options, diagnostic_type)
			@diagnostics = []
			@options = options
			@diagnostic_type = diagnostic_type
			@diagnostic_array = Hive.config.diagnostic[@diagnostic_type].keys 
	    end

		def initialize_diagnostic(diagnostic_details)
      		@diagnostic_array.each { |component|
      			Hive.logger.info("Initializing #{component.capitalize} component for #{@diagnostic_type.capitalize} diagnostic")
	        	require "hive/diagnostic/#{@diagnostic_type}/#{component}"
	        	@diagnostics << Object.const_get('Hive').const_get('Diagnostic').const_get(@diagnostic_type.capitalize).const_get(component.capitalize).new(diagnostic_details[@diagnostic_type][component])
			}
	    end 

		def run	
			@diagnostics.each{ |diagnostic|
				diagnostic.run(@options) unless !diagnostic.should_run?
			}
		end

		def repair
			# Should be either called from here or from within diagnostic ? 
		end
	end
end