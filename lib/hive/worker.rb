require 'yaml'

require 'hive'
require 'hive/job_paths'
require 'hive/execution_script'

require 'hive/messages'
require 'code_cache'

module Hive
  # The generic worker class
  class Worker
    class InvalidJobReservationError < StandardError
    end

    class DeviceNotReady < StandardError
    end

    # The main worker process loop
    def initialize(options)
      @options = options
      @parent_pid = @options['parent_pid']
      @device_id = @options['id']
      pid = Process.pid
      $PROGRAM_NAME = "#{@options['name_stub'] || 'WORKER'}.#{pid}"
      @log = Hive::Log.new
      @log.add_logger(
        "#{LOG_DIRECTORY}/#{pid}.log",
        Hive.config.logging.worker_level || 'INFO'
      )

      @queues = @options['queues'].class == Array ? @options['queues'] : []

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
      job = reserve_job
      if job.nil?
        @log.info('No job found')
      else
        @log.info('Job starting')
        begin
          execute_job(job)
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
      # TODO: Get hive id
      { hive_id: 1, worker_pid: Process.pid }
    end

    # Execute a job
    def execute_job(job)
      # Ensure that a killed worker cleans up correctly
      Signal.trap('TERM') do |s|
        @log.info "Worker terminated"
        @log.info "Post-execution cleanup"
        post_script(job, job_paths, script)

        # Upload results
        job_paths.finalise_results_directory
        upload_files(job, job_paths.results_path, job_paths.logs_path)
        job.error('Worker killed')
        exit
      end

      @log.info('Job starting')
      job.prepare(@device_id)
      
      exception = nil
      begin
        @log.info "Setting job paths"
        job_paths = Hive::JobPaths.new(job.job_id, Hive.config.logging.home, @log)

        if ! job.repository.to_s.empty?
          @log.info "Checking out the repository"
          checkout_code(job.repository, job_paths.testbed_path)
        end

        @log.info "Initialising execution script"
        script = Hive::ExecutionScript.new(job_paths, @log)

        @log.info "Setting the execution variables in the environment"
        script.set_env 'HIVE_RESULTS', job_paths.results_path
        job.execution_variables.to_h.each_pair do |var, val|
          script.set_env "HIVE_#{var.to_s}".upcase, val if ! val.kind_of?(Array)
        end

        @log.info "Appending test script to execution script"
        script.append_bash_cmd job.command
        

        job.start

        @log.info "Pre-execution setup"
        pre_script(job, job_paths, script)

        @log.info "Running execution script"
        exit_value = script.run
        job.end(exit_value)
      rescue => e
        exception = e
      end


      begin
        @log.info "Post-execution cleanup"
        post_script(job, job_paths, script)

        # Upload results
        job_paths.finalise_results_directory
        upload_files(job, job_paths.results_path, job_paths.logs_path)
        results = gather_results(job_paths)
        if results
          @log.info("The results are ...")
          @log.info(results.inspect)
          job.update_results(results)
        end
      rescue => e
        @log.info( "Post execution failed " + e.message  + " " + e.backtrace)
      end

      if exception
        job.error( exception.message )
        raise exception
      else
        job.complete
      end

      Signal.trap('TERM') do
        @log.info("Worker terminated")
        exit
      end

      exit_value == 0
    end

    # Diagnostics function to be extended in child class, as required
    def diagnostics
      status = device_status
      raise DeviceNotReady.new("Current device status: '#{status}'") if status != 'idle'
    end

    # Current state of the device
    # This method should be replaced in child classes, as appropriate
    def device_status
      'idle'
    end

    def update_queues
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
      else
        @log.warn("Queue list missing from DeviceDB response")
      end
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

    # Get a checkout of the repository
    def checkout_code(repository, checkout_directory)
      CodeCache.repo(repository).checkout(:head, checkout_directory) or raise "Unable to checkout repository #{repository}"
    end

    # Gather the results from the tests
    # This is the simplest case where the results are written to a file
    # Child classes will probably replace this function
    def gather_results(paths)
      file = "#{paths.results_path}/results.yml"
      @log.debug "Gathering data from #{file}"
      # Default values
      results = {
        running_count: 0,
        passed_count: 0,
        failed_count: 0,
        errored_count: 0
      }
      data = {}
      if File.file?(file)
        @log.debug "#{file} exists"
        results.merge(YAML.load_file(file).symbolize_keys)
      else
        @log.debug "#{file} does not exist"
        nil
      end
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
    def pre_script(job, job_paths, script)
    end

    # Any device specific steps immediately after the execution script
    def post_script(job, job_paths, script)
    end

    # Do whatever device cleanup is required
    def cleanup
    end
  end
end
