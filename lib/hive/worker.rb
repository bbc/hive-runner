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

    attr_reader :type
    attr_reader :pid

    # A worker process is forked on creation.
    # In the master thread, the worker instance is used to control the forked
    # process.
    def initialize(options)
      @controller_pid = Process.pid
      @pid = Process.fork do
        worker_process(options)
      end

      LOG.info("Worker started with pid #{@pid}")
    end

    # Terminate the worker process
    def stop
      # TODO: Which of these is preferable to avoid leaving a zombie process?

      # Detach then kill
      Process.detach @pid
      Process.kill 'TERM', @pid

      # Kill then clean up
      # Process.kill 'TERM', @pid
      # Process.wait @pid
    end

    # Test the state of the worker process
    def running?
      begin
        Process.kill 0, @pid
        true
      rescue Errno::ESRCH
        false
      end
    end

    private

    # Methods below this line are used by the forked process

    # The main worker process loop
    def worker_process(options)
      pid = Process.pid
      $PROGRAM_NAME = "#{options['name_stub'] || 'WORKER'}.#{pid}"
      @log = Hive::Log.new
      @log.add_logger(
        "#{LOG_DIRECTORY}/#{pid}.log",
        Chamber.env.logging.worker_level || 'INFO'
      )

      @queues = options['queues'].class == Array ? options['queues'] : []

      Hive::Messages.configure do |config|
        config.base_path = Chamber.env.network.scheduler
        config.pem_file = Chamber.env.network.cert
        config.ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      @log.info('Starting worker')
      while keep_running?
        begin
          diagnostics
          poll_queue
        rescue StandardError => e
          @log.warn("Worker loop aborted: #{e.message}\n  : #{e.backtrace.join("\n  : ")}")
        end
        sleep Chamber.env.timings.worker_loop_interval
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
        job.start( 123 ) # TODO: Device ID

        begin
          # TODO: Use job.success and job.fail, when implemented
          execute_job(job) ? job.end : job.end
        rescue => e
          @log.info("Error running test: #{e.message}\n : #{e.backtrace.join("\n :")}")
          # TODO: job.error(e.message), when implemented
          job.error
        end
        cleanup
      end
    end

    # Try to find and reserve a job
    def reserve_job
      @log.info "Trying to reserve job for queues: #{@queues.join(', ')}"
      job = job_message_klass.reserve(@queues, reservation_details)
      @log.debug "Job: #{job.inspect}"
      raise InvalidJobReservationError.new("Invalid Job Reserved") unless job.valid? if job.present?
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
      @log.info "Setting job paths"
      job_paths = Hive::JobPaths.new(job.job_id, Chamber.env.logging.env.home, @log)

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

      @log.info "Running execution script"
      state = script.run

      # Upload results
      # TODO: Do this outside of the execute_job method
      job_paths.finalise_results_directory
      upload_files(job, job_paths.results_path, job_paths.logs_path)
      results = gather_results(job_paths)
      if results
        @log.info("The results are ...")
        @log.info(results.inspect)
        job.update_results(results)
      end

      state
    end

    # Dummy function to be replaced in child class, as required
    def diagnostics
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
    # This just checks the presense of the controller process
    def keep_running?
      begin
        Process.getpgid(@controller_pid)
        true
      rescue
        false
      end
    end

    # Do whatever device cleanup is required
    def cleanup
    end
  end
end
