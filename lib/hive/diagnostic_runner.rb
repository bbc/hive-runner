module Hive
	class DiagnosticRunner		
		def initialize(options, diagnostics_type)
			@diagnostics = []
			@options = options
			@diagnostics_type = diagnostics_type
			@diagnostic_array = Hive.config.diagnostics[@diagnostics_type].keys 
		end

		def initialize_diagnostic(diagnostics_details)
			@diagnostic_array.each { |component|
				Hive.logger.info("Initializing #{component.capitalize} component for #{@diagnostics_type.capitalize} diagnostic")
				require "hive/diagnostic/#{@diagnostics_type}/#{component}"
				@diagnostics << Object.const_get('Hive').const_get('Diagnostic').const_get(@diagnostics_type.capitalize).const_get(component.capitalize).new(diagnostics_details[@diagnostics_type][component])
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