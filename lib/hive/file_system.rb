require "fileutils"

module Hive
  class FileSystem
    def initialize(job_id, home_directory, log)
      @job_id = job_id
      @home_directory = home_directory
      @log = log
      @log.debug "Creating job paths with id=#{@job_id} and home=#{@home_directory}"
      make_directory(home_path)
      make_directory(results_path)
      make_directory(logs_path)
      make_directory(testbed_path)
    end

    def home_path
      @home_path ||= "#{@home_directory}/#{@job_id.to_s}"
    end

    def results_path
      @results_path ||= "#{home_path}/results"
    end

    def logs_path
      @logs_path ||= "#{home_path}/logs"
    end

    def testbed_path
      @testbed_path ||= "#{home_path}/test_code"
    end

    def executed_script_path
      @bash_script_path ||= "#{testbed_path}/executed_script.sh"
    end

    def results_file
      @results_file ||= "#{testbed_path}/results.yml"
    end

    def finalise_results_directory
      copy_file(executed_script_path, "#{results_path}/executed_script.sh")
      if File.file?(results_file)
        copy_file(results_file, "#{results_path}/results.yml")
      end
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

    private

    def copy_file(src, dest)
      begin
        FileUtils.cp(src, dest)
        @log.debug("Copied file #{src} -> #{dest}")
      rescue => e
        @log.error(e.message)
      end
    end

    def make_directory(directory)
      begin
        FileUtils.rm_r(directory) if File.directory?(directory)
        FileUtils.mkdir_p(directory)
        @log.debug("Created directory: #{directory}")
      rescue => e
        @log.fatal(e.message)
      end
    end
  end
end
