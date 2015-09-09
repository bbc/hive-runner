module Hive
  class DiagnosticRunner
    attr_accessor :diagnostics, :options

    def initialize(options, diagnostics_config, platform)
      @options = options
      @platform = platform
      @diagnostics = self.initialize_diagnostics(diagnostics_config[@platform]) if diagnostics_config.has_key?(@platform)
    end

    def initialize_diagnostics(diagnostics_config)
      @diagnostics = diagnostics_config.collect do |component, config|
        Hive.logger.info("Initializing #{component.capitalize} component for #{@platform.capitalize} diagnostic")
        require "hive/diagnostic/#{@platform}/#{component}"
        Object.const_get('Hive').const_get('Diagnostic').const_get(@platform.capitalize).const_get(component.capitalize).new(config, @options)
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