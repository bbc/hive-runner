module Hive
	class DiagnosticRunner
	  attr_accessor :diagnostics
	  
		def initialize(options, diagnostics_config, device)
			@diagnostics = self.initalize_diagnostics(diagnostics_config, device)
		end

		def initialize_diagnostic(diagnostics_config)
			diagnostic_config.collect do |component, config|
				Hive.logger.info("Initializing #{component.capitalize} component for #{@diagnostics_type.capitalize} diagnostic")
				require "hive/diagnostic/#{@diagnostics_type}/#{component}"
				Object.const_get('Hive').const_get('Diagnostic').const_get(@diagnostics_type.capitalize).const_get(component.capitalize).new(diagnostics_details[@diagnostics_type][component])
			end
		end 

		def run	
			results = diagnostics.collect do |diagnostic|
				diagnostic.run
		  end
		  failures = results.select { |r| r.failed? }
		  failures.count == 0
		end

	end
end
