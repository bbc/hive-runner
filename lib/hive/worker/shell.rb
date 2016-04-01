require 'hive/worker'

module Hive
  class Worker
    # The Shell worker
    class Shell < Worker
      def initialize(options = {})
        #@devicedb_register = false
        super
      end

      def pre_script(job, file_system, script)
      end
    end
  end
end
