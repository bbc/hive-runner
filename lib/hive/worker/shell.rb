require 'hive/worker'

module Hive
  class Worker
    # The Shell worker
    class Shell < Worker
      def initialize(parent_pid, options)
        @type = 'shell'
        super
      end
    end
  end
end
