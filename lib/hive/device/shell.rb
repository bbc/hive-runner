require 'hive/device'

module Hive
  class Device
    # The Shell device
    class Shell < Device
      def initialize(config)
        Hive.logger.info("    In the shell device constructor")
        @identity = config['id']
        super
      end
    end
  end
end
