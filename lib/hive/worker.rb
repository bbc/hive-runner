require 'yaml'

require 'hive'
require 'hive/file_system'
require 'hive/execution_script'
require 'hive/diagnostic_runner'
require 'hive/messages'
require 'hive/port_allocator'
require 'code_cache'
require 'res'

module Hive
  # The generic worker class
  class Worker
    class InvalidJobReservationError < StandardError
    end

    class DeviceNotReady < StandardError
    end

    class NoPortsAvailable < StandardError
    end

    # Device API Object for device associated with this worker
    attr_accessor :device_api, :queues 

    # The main worker process loop
    def initialize(options)
      @options = options
      @parent_pid = @options['parent_pid']
      @device_id = @options['id']
      @device_identity = @options['device_identity'] || 'unknown-device'
      pid = Process.pid
      $PROGRAM_NAME = "#{@options['name_stub'] || 'WORKER'}.#{pid}"
      @log = Hive::Log.new
      @log.add_logger(
        "#{LOG_DIRECTORY}/#{pid}.#{@device_identity}.log",
        Hive.config.logging.worker_level || 'INFO'
      )
      @devicedb_register = true if @devicedb_register.nil?

      @queues = @options['queues'].class == Array ? @options['queues'] : []
      self.update_queue_log

      @port_allocator = (@options.has_key?('port_allocator') ? @options['port_allocator'] : Hive::PortAllocator.new(ports: []))
      
      platform = self.class.to_s.scan(/[^:][^:]*/)[2].downcase
      @diagnostic_runner = Hive::DiagnosticRunner.new(@options, Hive.config.diagnostics, platform) if !Hive.config["diagnostics"].nil?

      Hive::Messages.configure do |config|
        config.base_path = Hive.config.network.scheduler
        config.pem_file = Hive.config.network.cert
        config.ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      Signal.trap('TERM') do
        @log.info("Worker terminated")
        exit
      end

      @log.info('Starting worker')
      while keep_running?
        begin
          diagnostics
          update_queues
          poll_queue
        rescue DeviceNotReady => e
          @log.info("#{e.message}\n");
        rescue StandardError => e
          @log.warn("Worker loop aborted: #{e.message}\n  : #{e.backtrace.join("\n  : ")}")
        end
        sleep Hive.config.timings.worker_loop_interval
      end
      @log.info('Exiting worker')
    end

    # Check the queues for work
    def poll_queue
      @job = reserve_job
      if @job.nil?
        @log.info('No job found')
      else
        @log.info('Job starting')
        begin
          execute_job
        rescue => e
          @log.info("Error running test: #{e.message}\n : #{e.backtrace.join("\n :")}")
        end
        cleanup
      end
    end

    # Try to find and reserve a job
    def reserve_job
      @log.info "Trying to reserve job for queues: #{@queues.join(', ')}"
      job = job_message_klass.reserve(@queues, reservation_details)
      @log.debug "Job: #{job.inspect}"
      raise InvalidJobReservationError.new("Invalid Job Reserved") if ! (job.nil? || job.valid?)
      job
    end

    # Get the correct job class
    # This should usually be replaced in the child class
    def job_message_klass
      @log.info 'Generic job class'
      Hive::Messages::Job
    end

    def reservation_details
      { hive_id: Hive.id, worker_pid: Process.pid }
    end

    # Execute a job
    def execute_job
      # Ensure that a killed worker cleans up correctly
      Signal.trap('TERM') do |s|
        Signal.trap('TERM') {} # Prevent retry signals
        @log.info "Caught TERM signal"
        @log.info "Terminating script, if running"
        @script.terminate if @script
        @log.info "Post-execution cleanup"
        signal_safe_post_script(@job, @file_system, @script)

        # Upload results
        @file_system.finalise_results_directory
        upload_files(@job, @file_system.results_path, @file_system.logs_path)
        File.open("#{@file_system.home_path}/job_info", 'w') do |f|
          f.puts "#{Process.pid} completed"
        end
        @job.error('Worker killed')
        @log.info "Worker terminated"
        exit
      end

      @log.info('Job starting')
      @job.prepare(@device_id)
      
      exception = nil
      begin
        @log.info "Setting job paths"
        @file_system = Hive::FileSystem.new(@job.job_id, Hive.config.logging.home, @log)
        File.open("#{@file_system.home_path}/job_info", 'w') do |f|
          f.puts "#{Process.pid} running"
        end

        if ! @job.repository.to_s.empty?
          @log.info "Checking out the repository"
          @log.debug "  #{@job.repository}"
          @log.debug "  #{@file_system.testbed_path}"
          checkout_code(@job.repository, @file_system.testbed_path)
        end

        @log.info "Initialising execution script"
        @script = Hive::ExecutionScript.new(
          file_system: @file_system,
          log: @log,
          keep_running: ->() { self.keep_running? }
        )
        @script.append_bash_cmd "mkdir -p #{@file_system.testbed_path}/#{@job.execution_directory}"
        @script.append_bash_cmd "cd #{@file_system.testbed_path}/#{@job.execution_directory}"

        @log.info "Setting the execution variables in the environment"
        @script.set_env 'HIVE_RESULTS', @file_system.results_path
        @job.execution_variables.to_h.each_pair do |var, val|
          @script.set_env "HIVE_#{var.to_s}".upcase, val if ! val.kind_of?(Array)
        end

        @log.info "Appending test script to execution script"
        @script.append_bash_cmd @job.command

        @job.start

        @log.info "Pre-execution setup"
        pre_script(@job, @file_system, @script)

        @log.info "Running execution script"
        exit_value = @script.run
        @job.end(exit_value)
      rescue => e
        exception = e
      end

      begin
        @log.info "Post-execution cleanup"
        post_script(@job, @file_system, @script)

        # Upload results
        @file_system.finalise_results_directory
        upload_files(@job, @file_system.results_path, @file_system.logs_path)
        upload_results(@job, @file_system.testbed_path, @file_system.results_path)
      rescue => e
        @log.error( "Post execution failed: " + e.message)
        @log.error("  : #{e.backtrace.join("\n  : ")}")
      end

      if exception
        @job.error( exception.message )
        raise exception
      else
        @job.complete
      end

      Signal.trap('TERM') do
        @log.info("Worker terminated")
        exit
      end

      File.open("#{@file_system.home_path}/job_info", 'w') do |f|
        f.puts "#{Process.pid} completed"
      end
      exit_value == 0
    end

    # Diagnostics function to be extended in child class, as required
    def diagnostics
      @diagnostic_runner.run if !@diagnostic_runner.nil?
      status = device_status
      status = set_device_status('idle') if status == 'busy'
      raise DeviceNotReady.new("Current device status: '#{status}'") if status != 'idle'
    end

    # Current state of the device
    # This method should be replaced in child classes, as appropriate
    def device_status
      @device_status ||= 'idle'
    end

    # Set the status of a device
    # This method should be replaced in child classes, as appropriate
    def set_device_status(status)
      @device_status = status
    end

    def update_queues
      if @devicedb_register
        details = Hive.devicedb('Device').find(@options['id'])
        @log.debug("Device details: #{details.inspect}")

        if details['device_queues']
          new_queues = details['device_queues'].collect do |queue_details|
            queue_details['name']
          end
          if @queues.sort != new_queues.sort
            @log.info("Updated queue list: #{new_queues.join(', ')}")
            @queues = new_queues
          end
          update_queue_log
        else
          @log.warn("Queue list missing from DeviceDB response")
        end
      end
    end
    
    def update_queue_log
      File.open("#{LOG_DIRECTORY}/#{Process.pid}.queues.yml",'w') { |f| f.write @queues.to_yaml}
    end

    # Upload any files from the test
    def upload_files(job, *paths)
      @log.info("Uploading assets")
      paths.each do |path|
        @log.info("Uploading files from #{path}")
        Dir.foreach(path) do |item|
          @log.info("File: #{item}")
          next if item == '.' or item == '..'
          begin
            artifact = job.report_artifact("#{path}/#{item}")
            @log.info("Artifact uploaded: #{artifact.attributes.to_s}")
          rescue => e
            @log.error("Error uploading artifact #{item}: #{e.message}")
            @log.error("  : #{e.backtrace.join("\n  : ")}")
          end
        end
      end
    end

    # Update results
    def upload_results(job, checkout, results_dir)

      res_file = detect_res_file(results_dir) || process_xunit_results(results_dir)
      
      if res_file
        @log.info("Res file found")
      
        begin
          Res.submit_results(
            reporter: :hive,
            ir: res_file,
            job_id: job.job_id
          )
        rescue => e
          @log.warn("Res Hive upload failed #{e.message}")
        end
      
        begin
          if conf_file = testmine_config(checkout)
            Res.submit_results(
              reporter: :testmine,
              ir: res_file,
              config_file: conf_file,
              hive_job_id: job.job_id,
              version: job.execution_variables.version,
              target: job.execution_variables.queue_name
            )
          end
        rescue => e
          @log.warn("Res Testmine upload failed #{e.message}")
        end
        
        # TODO Add in Testrail upload
      
      end
      
    end

    def detect_res_file(results_dir)
      Dir.glob( "#{results_dir}/*.res" ).first
    end
    
    def process_xunit_results(results_dir)
      #TODO Turn xml file into a res file with res parser
    end
    
    def testmine_config(checkout)
      Dir.glob( "#{checkout}/.testmi{n,t}e.yml" ).first
    end

    # Get a checkout of the repository
    def checkout_code(repository, checkout_directory)
      CodeCache.repo(repository).checkout(:head, checkout_directory) or raise "Unable to checkout repository #{repository}"
    end

    # Determine whether to keep the worker running
    # This just checks the presense of the parent process
    def keep_running?
      begin
        Process.getpgid(@parent_pid)
        true
      rescue
        false
      end
    end

    # Any setup required before the execution script
    def pre_script(job, file_system, script)
    end

    # Any device specific steps immediately after the execution script
    def post_script(job, file_system, script)
      signal_safe_post_script(job, file_system, script)
    end

    # Any device specific steps immediately after the execution script
    # that can be safely run in the a Signal.trap
    # This should be called by post_script
    def signal_safe_post_script(job, file_system, script)
    end

    # Do whatever device cleanup is required
    def cleanup
    end

    # Allocate a port
    def allocate_port
      @log.warn("Using deprecated 'Hive::Worker.allocate_port' method")
      @log.warn("Use @port_allocator.allocate_port instead")
      @port_allocator.allocate_port
    end

    # Release a port
    def release_port(p)
      @log.warn("Using deprecated 'Hive::Worker.release_port' method")
      @log.warn("Use @port_allocator.release_port instead")
      @port_allocator.release_port(p)
    end

    # Release all ports
    def release_all_ports
      @log.warn("Using deprecated 'Hive::Worker.release_all_ports' method")
      @log.warn("Use @port_allocator.release_all_ports instead")
      @port_allocator.release_all_ports
    end
  end
end
