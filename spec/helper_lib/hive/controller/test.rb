require 'hive/controller'

module Hive
  class Controller
    # Dummy test controller
    class Test < Controller
      def initialize(config)
        @type = 'test'
        super
      end
    end
  end
end
