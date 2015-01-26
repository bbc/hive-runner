require 'timeout'

module Hive
  class ExecutionScript
    def initialize(job_paths, logger)
      @path = job_paths.executed_script_path
      @log_path = job_paths.logs_path
      @log = logger
      @log.debug "Creating execution script with path=#{@path}"
      @env = {
        'HIVE_WORKING_DIRECTORY' => job_paths.testbed_path,
        'RESULTS_FILE' => job_paths.results_file
      }
      @script_lines = []
    end

    def append_bash_cmd(shell_command)
      @log.debug "bash.rb - Appending bash command to #{@path} script: " + shell_command
      @script_lines << shell_command
    end

    def run
      @log.info 'bash.rb - Writing script out to file'
      File.open(@path, 'w') do |f|
        f.write("#!/bin/bash\n")
        f.write("# Set environment\n")
        @env.each do |key, value|
          f.write("export #{key}=#{value}\n")
        end
        f.write("cd $HIVE_WORKING_DIRECTORY")
        f.write("\n# Test execution\n")
        f.write(@script_lines.join("\n"))
      end
      File.chmod(0700, @path)

      pid = Process.spawn "#{@path} > #{@log_path}/log.out 2> #{@log_path}/log.err", pgroup: true
      pgid = Process.getpgid(pid)

      running = true
      while running
        begin
          Timeout.timeout(5) do
            Process.wait pid
            running = false
          end
        rescue Timeout::Error
          # Do something. Eg, upload log files.
        end
      end

      # Kill off anything that is still running
      begin
        Process.kill(-9, pgid)
      rescue => e
        @log.warn e
      end
    end
  end
end
