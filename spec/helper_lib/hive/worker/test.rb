require 'hive/worker'

module Hive
  class Worker
    # Dummy test worker
    class Test < Worker
      def initialize(config)
        super
      end

      def poll_queue
      end
    end
  end
end
