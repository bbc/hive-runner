require 'hive/worker'

module Hive
  class Worker
    # The Shell worker
    class Shell < Worker
      def initialize(options = {})
        @devicedb_register = false
        super
      end

      def pre_script(job, file_system, script)
        @ports.each do |label, port|
          @log.debug("Add port #{label} (#{port}) as environment variable")
          script.set_env "HIVE_PORT_#{label.upcase}", port
        end
      end
    end
  end
end
