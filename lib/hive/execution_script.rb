module Hive
  class ExecutionScript
    def initialize(path, logger)
      @path = path
      @log = logger
      @log.debug "Creating execution script with path=#{@path}"
      @script_lines = []
    end

    def append_bash_cmd(shell_command)
      @log.debug "bash.rb - Appending bash command to #{@path} script: " + shell_command
      @script_lines << shell_command
    end

    def run
      @log.info 'bash.rb - Writing script out to file'
      File.open(@path, 'w') do |f|
        f.write("\n# Test execution\n")
        f.write(@script_lines.join("\n"))
      end
    end
  end
end
