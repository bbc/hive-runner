require 'hive/controller'
require 'hive/worker/shell'

module Hive
  class Controller
    # The Shell controller
    class Shell < Controller
      def initialize(config)
        @type = 'shell'
        super
      end
    end
  end
end
