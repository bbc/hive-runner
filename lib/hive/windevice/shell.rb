require 'hive/windevice'

module Hive
  class Windevice
    # The Windows shell device
    class Shell < Windevice
      def initialize(config)
        Hive.logger.info("In the Windows device constructor")
        @identity = config['id']
        super(config)
      end
    end
  end
end
