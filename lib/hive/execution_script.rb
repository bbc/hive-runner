require 'timeout'

module Hive
  class ExecutionScript
    def initialize(job_paths, log)
      @path = job_paths.executed_script_path
      @log_path = job_paths.logs_path
      @log = log
      @log.debug "Creating execution script with path=#{@path}"
      @env = {
        'HIVE_SCHEDULER' => Hive.config.network.scheduler,
        'HIVE_WORKING_DIRECTORY' => job_paths.testbed_path,
        'RESULTS_FILE' => job_paths.results_file
      }
      @env_unset = [
        'BUNDLE_GEMFILE',
        'BUNDLE_BIN_PATH',
        'GEM_PATH',
        'RUBYOPT',
        'rvm_'
      ]
      # Environment variables that should not be made visible in the execution
      # script uploaded with the results
      @env_secure = {
        'HIVE_CERT' => Hive.config.network.cert
      }
      @script_lines = []
    end

    def append_bash_cmd(shell_command)
      @log.debug "bash.rb - Appending bash command to #{@path} script: " + shell_command
      @script_lines << shell_command
    end

    def set_env(var, value)
      @env[var] = value

      # TODO What if the element appears multiple times?
      if (i = @env_unset.index(var))
        @env_unset.delete(i)
      end

      ## In Ruby 2, replace the above 'if' block with ...
      #@env_unset.remove(var)
    end

    def unset_env(var)
      @env.delete(var)
      @env_unset << var
    end


    def fetch_build(build_url, destination_path)
      if !fetch_build_with_curl(build_url, destination_path)
        @log.info( "Initial build fetch failed -- trying again shortly")
        sleep 5
        if !fetch_build_with_curl(build_url, destination_path)
          raise "Build could not be downloaded"
        end
      end
    end

    def fetch_build_with_curl(build_url, destination_path)
      cert_path     = Hive.config.network['cert']
      cabundle_path = Hive.config.network['cafile']
      base_url      = Hive.config.network['scheduler']
      apk_url       = base_url + '/' + build_url
      curl_line     = "curl -L -m 60 #{apk_url} --cert #{cert_path} --cacert #{cabundle_path} --retry 3 -o #{destination_path}"

      @log.info("Fetching build from hive-scheduler: #{curl_line}")
      @log.debug("CURL line: #{curl_line}")
      response = `#{curl_line}`
      if $? != 0
        @log.info("Curl error #{$?}: #{response.to_s}")
        false
        Hive::Messages
      else
        @log.info("Curl seems happy, checking integrity of downloaded file")
        check_build_integrity( destination_path )
      end
    end

    def check_build_integrity( destination_path )
      output = `file #{destination_path}`
      if output =~ /zip/
        result = `zip -T #{destination_path}`
        @log.info(result)
        $? == 0
      else
        true
      end
    end

    def run
      @log.info 'bash.rb - Writing script out to file'
      File.open(@path, 'w') do |f|
        f.write("#!/bin/bash --login\n")
        f.write("# Set environment\n")
        @env.each do |key, value|
          f.write("export #{key}=#{value}\n")
        end
        @env_unset.each do |var|
          f.write("unset #{var}\n")
        end
        f.write("cd $HIVE_WORKING_DIRECTORY")
        f.write("\n# Test execution\n")
        f.write(@script_lines.join("\n"))
      end
      File.chmod(0700, @path)

      pid = Process.spawn @env_secure, "#{@path} > #{@log_path}/stdout.log 2> #{@log_path}/stderr.log", pgroup: true
      pgid = Process.getpgid(pid)

      exit_value = nil
      running = true
      while running
        begin
          Timeout.timeout(5) do
            Process.wait pid
            exit_value = $?.exitstatus
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

      # Return exit value of the script
      exit_value
    end
  end
end
