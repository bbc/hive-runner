require 'hive/worker'

module Hive
  class Worker
    # Dummy test worker
    class Test < Worker
      def initialize(parent_pid, config)
        super
      end
    end
  end
end
