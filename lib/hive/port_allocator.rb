module Hive
  class PortAllocator
    class NoPortsAvailable < StandardError
    end

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

    def allocate_port
      if p = @free_ports.pop
        @allocated_ports << p
        p
      else
        raise NoPortsAvailable
      end
    end

    def release_port(p)
      @free_ports << p if @allocated_ports.delete(p)
    end

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

    def release_port_range(range)
      if range.ports - @allocated_ports == []
        @free_ports.concat(range.ports)
        @allocated_ports = @allocated_ports - range.ports
      end
    end

    def ports
      [@free_ports, @allocated_ports].flatten
    end
  end
end
