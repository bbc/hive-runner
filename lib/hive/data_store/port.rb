module Hive
  class DataStore
    # Port allocations
    class Port < ActiveRecord::Base
      validates :port, uniqueness: true

      # TODO Make this configurable
      MINIMUM_PORT = 4000
      MAXIMUM_PORT = 5000

      class NoPortsAvailable < StandardError
      end

      def self.assign(worker)
        # Check to see if all ports have been taken
        raise NoPortsAvailable if self.all.length >= MAXIMUM_PORT - MINIMUM_PORT + 1

        @next_port ||= MINIMUM_PORT
        has_looped = false
        while self.find_by(port: @next_port)
          Hive.logger.debug "#{@next_port} in use"
          @next_port += 1
          if @next_port > MAXIMUM_PORT
            raise NoPortsAvailable if has_looped
            has_looped = true
            @next_port = MINIMUM_PORT
          end
        end

        Hive.logger.debug "Allocated #{@next_port} to worker #{worker}"
        p = self.new(port: @next_port, worker: worker)
        @next_port += 1
        p.save
        p.port
      end

      def self.release(port)
        self.find_by(port: port).delete
      end
    end
  end
end
