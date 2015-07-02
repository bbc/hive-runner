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