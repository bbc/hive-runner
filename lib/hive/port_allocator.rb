module Hive
  class PortAllocator
    class NoPortsAvailable < StandardError
    end

    # Create a port allocator
    #
    # For ports in the range 4000-5000
    #   Hive::PortAllocator.new(minimum: 4000, maximum: 5000)
    #
    # For ports 6000, 6050 and 7433
    #   Hive::PortAllocator.new(ports: [6000, 6050, 7433])
    #
    def initialize(config)
      @allocated_ports = []
      if config.has_key?(:minimum) and config.has_key?(:maximum) and config[:minimum] > 0 and config[:minimum] <= config[:maximum]
        @free_ports = Array(config[:minimum]..config[:maximum])
      elsif config.has_key?(:ports) and config[:ports].is_a? Array
        config[:ports].each do |p|
          raise ArgumentError if ! p.is_a? Integer or p <= 0
        end
        @free_ports = config[:ports]
      else
        raise ArgumentError
      end
    end

    # Allocate a single port in the range
    def allocate_port
      if p = @free_ports.pop
        @allocated_ports << p
        p
      else
        raise NoPortsAvailable
      end
    end

    # Relase a single port in the range
    def release_port(p)
      @free_ports << p if @allocated_ports.delete(p)
    end

    # Create a new Hive::PortAllocator instance with a number of ports from
    # the range
    def allocate_port_range(n)
      if n <= @free_ports.length
        ps = @free_ports.take(n)
        @free_ports = @free_ports.drop(n)
        @allocated_ports.concat(ps)
        PortAllocator.new(ports: ps)
      else
        raise NoPortsAvailable
      end
    end

    # Release ports that were previously allocated to another
    # Hive::PortAllocator
    #
    # Note, this will fail silently if 'range' contains ports that are not
    # allocated in the current instance
    def release_port_range(range)
      if range.ports - @allocated_ports == []
        @free_ports.concat(range.ports)
        @allocated_ports = @allocated_ports - range.ports
      end
    end

    # Full list of all ports, either free or allocated
    def ports
      [@free_ports, @allocated_ports].flatten
    end
  end
end
