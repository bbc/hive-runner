require 'hive/device'

module Hive
  class Device
    # Dummy test worker
    class Test < Device
      def initialize(config)
        @identity = config['id']
        super
      end
    end
  end
end
