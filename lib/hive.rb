require 'chamber'
require 'hive/log'
require 'hive/register'
require 'devicedb_comms'
require 'mind_meld'
require 'macaddr'
require 'socket'

# The Hive automated testing framework
module Hive
  Chamber.load(
    basepath: ENV['HIVE_CONFIG'] || './config/',
    namespaces: {
      environment: ENV['HIVE_ENVIRONMENT'] || 'test'
    }
  )
  DAEMON_NAME = Chamber.env.daemon_name? ? Chamber.env.daemon_name : 'HIVE'

  if Chamber.env.logging?
    if Chamber.env.logging.directory?
      LOG_DIRECTORY = Chamber.env.logging.directory
    else
      fail 'Missing log directory'
    end
    if Chamber.env.logging.pids?
      PIDS_DIRECTORY = Chamber.env.logging.pids
    else
      PIDS_DIRECTORY = LOG_DIRECTORY
    end
  else
    fail 'Missing logging section in configuration file'
  end

  DeviceDBComms.configure do |config|
    config.url = Chamber.env.network.devicedb
    config.pem_file = Chamber.env.network.cert
    config.ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  def self.config
    Chamber.env
  end

  def self.logger
    if ! @logger
      @logger = Hive::Log.new

      if Hive.config.logging.main_filename?
        @logger.add_logger("#{LOG_DIRECTORY}/#{Hive.config.logging.main_filename}", Chamber.env.logging.main_level? ? Chamber.env.logging.main_level : 'INFO')
      end
      if Hive.config.logging.console_level?
        @logger.add_logger(STDOUT, Hive.config.logging.console_level)
      end
    end
    @logger
  end

  def self.devicedb(section)
    @devicedb = {} if ! @devicedb.kind_of?(Hash)
    @devicedb[section] ||= Object.const_get('DeviceDBComms').const_get(section).new()
  end

  def self.hive_mind
    @hive_mind ||= MindMeld.new(
      url: Chamber.env.network.hive_mind? ? Chamber.env.network.hive_mind : nil,
      device: {
        hostname: Hive.hostname,
        version: Gem::Specification.find_by_name('hive-runner').version.to_s,
        runner_plugins: Hash[Gem::Specification.find_all_by_name(/hive-runner-/).map { |p| [p.name, p.version.to_s] }],
        macs: [Hive.mac_address],
        ips: [Hive.ip_address],
        brand: Hive.config.brand? ? Hive.config.brand : 'BBC',
        model: Hive.config.model? ? Hive.config.model : 'Hive',
        device_type: 'Hive'
      }
    )
  end

  def self.register
    @register ||= Hive::Register.new
  end

  # Get the id of the hive from the device database
  def self.id
    if ! @devicedb_id
      Hive.logger.info "Attempting to register the hive as #{Hive.hostname}"
      register_response = self.devicedb('Hive').register(Hive.hostname, Hive.mac_address, Hive.ip_address)
      if register_response['error'].present?
        Hive.logger.warn 'Hive failed to register'
        Hive.logger.warn "  - #{register_response['error']}"
      else
        Hive.logger.info "Hive registered with id #{register_response['id']}"
        @devicedb_id = register_response['id']
      end
    end
    @devicedb_id || -1
  end

  # Poll the device database
  def self.poll
    # DeviceDB
    id = self.id
    if id and  id > 0
      Hive.logger.debug "Polling hive: #{id}"
      rtn = Hive.devicedb('Hive').poll(id)
      Hive.logger.debug "Return data: #{rtn}"
      if rtn['error'].present?
        Hive.logger.warn "Hive polling failed: #{rtn['error']}"
      else
        Hive.logger.info "Successfully polled hive"
      end
    else
      if id
        Hive.logger.debug "Skipping polling of hive"
      else
        Hive.logger.warn "Unable to poll hive"
      end
    end

    # Hive Mind
    Hive.logger.debug "Polling hive: #{id}"
    rtn = Hive.hive_mind.poll
    Hive.logger.debug "Return data: #{rtn}"
    if rtn['error'].present?
      Hive.logger.warn "Hive polling failed: #{rtn['error']}"
    else
      Hive.logger.info "Successfully polled hive"
    end
  end

  # Get the IP address of the Hive
  def self.ip_address
    ip = Socket.ip_address_list.detect { |intf| intf.ipv4_private? }
    ip.ip_address
  end

  # Get the MAC address of the Hive
  def self.mac_address
    Mac.addr
  end

  # Get the hostname of the Hive
  def self.hostname
    Socket.gethostname.split('.').first
  end

end
