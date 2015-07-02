module Hive
	class DiagnosticRunner
		attr_accessor :diagnostics, :options

		def initialize(options, diagnostics_config, device)
			@options = options
			@type = device
			@diagnostics = self.initialize_diagnostics(diagnostics_config[@type])
		end

		def initialize_diagnostics(diagnostics_config)
			@diagnostics = diagnostics_config.collect do |component, config|
				Hive.logger.info("Initializing #{component.capitalize} component for #{@type.capitalize} diagnostic")
				require "hive/diagnostic/#{@type}/#{component}"
				Object.const_get('Hive').const_get('Diagnostic').const_get(@type.capitalize).const_get(component.capitalize).new(config, @options['serial'])
			end
		end 

		def run
			results = @diagnostics.collect do |diagnostic|
			diagnostic.run
		end
		failures = results.select { |r| r.failed? }
			failures.count == 0
		end
	end
end





























=======
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
>>>>>>> 3d928af3ffa038ea1b69ce5b565b353d8e3c333b
