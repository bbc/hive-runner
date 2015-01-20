require "fileutils"

module Hive
  class JobPaths
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