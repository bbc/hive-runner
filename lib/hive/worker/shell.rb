require 'hive/worker'

module Hive
  class Worker
    # The Shell worker
    class Shell < Worker
      def initialize(options)
        @devicedb_register = false
        super
      end
    end
  end
end
