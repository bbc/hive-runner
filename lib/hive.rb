require 'chamber'
require 'hive/log'
require 'hive/register'
require 'hive/data_store'
require 'devicedb_comms'
require 'macaddr'
require 'socket'

# The Hive automated testing framework
module Hive
  Chamber.load(
    basepath: ENV['HIVE_CONFIG'] || File.expand_path('../../config', __FILE__),
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
    @devicedb[section] ||= Object.const_get('DeviceDBComms').const_get(section).new(
      Hive.config.network.devicedb,
      Hive.config.network.cert
    )
  end

  def self.register
    @register ||= Hive::Register.new
  end

  # Get the id of the hive from the device database
  def self.id
    if ! @devicedb_id
      Hive.logger.info "Attempting to register the hive as #{Hive.hostname}"
      @devicedb_hive ||= DeviceDBComms::Hive.new(
        Hive.config.network.devicedb,
        Hive.config.network.cert
      )
      register_response = @devicedb_hive.register(Hive.hostname, Hive.mac_address, Hive.ip_address)
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

  # The local datastore
  def self.data_store
    @data_store ||= Hive::DataStore.new(self.config.datastore.filename)
  end
end
