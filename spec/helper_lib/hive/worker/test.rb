require 'hive/worker'

module Hive
  class Worker
    # Dummy test worker
    class Test < Worker
      def initialize(config)
      end
    end
  end
end
