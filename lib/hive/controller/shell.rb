require 'hive/controller'
require 'hive/worker/shell'

module Hive
  class Controller
    # The Shell controller
    class Shell < Controller
      def initialize(options)
        Hive.logger.debug("options: #{options.inspect}")
        @maximum = options['maximum'] || 0
        super
      end

      def detect
        Hive.logger.info('Creating shell devices')
        (1..@maximum).collect do |i|
          Hive.logger.info("  Shell device #{i}")
          self.create_device('id' => i)
        end
      end
    end
  end
end
