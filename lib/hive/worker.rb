require 'yaml'

require 'hive'
require 'hive/job_paths'
require 'hive/execution_script'

require 'hive/messages'

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
      @parent_reader, @child_writer = IO.pipe
      @child_reader, @parent_writer = IO.pipe

      @controller_pid = Process.pid
      @pid = Process.fork do
        @parent_reader.close
        @parent_writer.close

        worker_process(options)
      end

      @child_reader.close
      @child_writer.close

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

    # Get the list of queues that the worker knows about
    def queues
      send_message "queues"
    end

    def add_queue(queue)
      send_message "add_queue #{queue}"
    end

    def remove_queue(queue)
      send_message "remove_queue #{queue}"
    end

    private

    # Send a message to the forked process and receive the response
    def send_message(message)
      Process.kill 'USR1', @pid
      @parent_writer.puts message
      response = []
      while (message = @parent_reader.gets) && ! /^\.\.\./.match(message)
        response << message.chomp
      end
      response
    end

    # Methods below this line are used by the forked process

    # The main worker process loop
    def worker_process(options)
      pid = Process.pid
      $PROGRAM_NAME = "#{options['name_stub'] || 'WORKER'}.#{pid}"
      @log = Hive::Log.new
      @log.add_logger(
        "#{LOG_DIRECTORY}/#{pid}.log",
        CONFIG['logging']['worker_level'] || 'INFO'
      )

      @queues = options['queues'].class == Array ? options['queues'] : []

      setup_ipc

      Hive::Messages.configure do |config|
        config.base_path = CONFIG['network']['scheduler']
        config.pem_file = CONFIG['network']['cert']
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
        sleep CONFIG['timings']['worker_loop_interval']
      end
      @log.info('Exiting worker')
    end

    # Set up the interprocess communication
    def setup_ipc
      Signal.trap('USR1') do
        command, arguments = @child_reader.gets.chomp.split(' ', 2)
        case command
        when 'queues'
          @queues.each do |q|
            @child_writer.puts q
          end
        when 'add_queue'
          @queues << arguments
          @queues.uniq!
        when 'remove_queue'
          @queues.delete(arguments)
        else
          @child_writer.puts 'Unknown command'
        end
        @child_writer.puts '...'
      end
    end

    # Check the queues for work
    def poll_queue
      job = reserve_job
      if job.nil?
        @log.info('No job found')
      else
        @log.info('Job starting')
        job.start( 123 ) # TODO: Device ID
        if execute_job(job)
          @log.info('Job ending')
          job.end
        else
          @log.info('Job terminating with error')
          job.error
        end
        cleanup
      end
    end

    # Try to find and reserve a job
    def reserve_job
      q = next_queue
      if q
        @log.info "Trying to reserve job for queue '#{q}'"
        job = job_message_klass.reserve(q, reservation_details)
        @log.info "Job: #{job.inspect}"
        if job.present?
          raise InvalidJobReservationError.new("Invalid Job Reserved") unless job.valid?
          return job
        end
      else
        @log.info "No queues for device"
      end
      nil
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
      begin
        @log.info "Setting job paths"
        job_paths = Hive::JobPaths.new(job.job_id, CONFIG['logging']['home'], @log)

        @log.info "Initialising execution script"
        script = Hive::ExecutionScript.new(job_paths, @log)

        @log.info "Appending test script to execution script"
        script.append_bash_cmd job.command

        @log.info "Running execution script"
        script.run

        # Upload results
        job_paths.finalise_results_directory
        upload_files(job, job_paths.results_path, job_paths.logs_path)
        results = gather_results(job_paths)
        @log.info("The results are ...")
        @log.info(results.inspect)
        job.update_results(results)

        true
      rescue Exception => e
        @log.error("Error running test: #{e.message}\n  : #{e.backtrace.join("\n  : ")}")
        false
      end
    end

    # Cycle the queue list and return the queue that has been move to the end
    def next_queue
      q = @queues.shift
      @queues << q
      q
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
        results
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
