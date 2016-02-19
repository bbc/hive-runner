require 'spec_helper'

require 'tmpdir'

require 'hive/log'
require 'hive/execution_script'

class FileSystemMock
  attr_reader :executed_script_path, :logs_path, :testbed_path

  def initialize
    @logs_path = Dir.mktmpdir
    @testbed_path = Dir.mktmpdir
    @executed_script_path = "#{@testbed_path}/execution_script.sh"
  end

  def cleanup
    FileUtils.remove_entry @logs_path
    FileUtils.remove_entry @testbed_path
  end
end

describe Hive::ExecutionScript do
  describe '#set_env' do
    let(:fs) { FileSystemMock.new }

    let(:es) { Hive::ExecutionScript.new(
      file_system: fs,
      log: Hive::Log.new,
      keep_running: nil
    ) }

    after(:each) do
      fs.cleanup
    end

    it 'sets an environment variable' do
      es.set_env('TEST_VAR', 'test_variable_value')
      es.append_bash_cmd('echo $TEST_VAR')
      es.run
      expect(File.read("#{fs.logs_path}/stdout.log")).to eq "test_variable_value\n"
    end

    it 'sets an environment variable to a number' do
      es.set_env('TEST_VAR', 99)
      es.append_bash_cmd('echo $TEST_VAR')
      es.run
      expect(File.read("#{fs.logs_path}/stdout.log")).to eq "99\n"
    end

    it 'sets an environment variable with spaces in it' do
      es.set_env('TEST_VAR', 'one two three')
      es.append_bash_cmd('echo $TEST_VAR')
      es.run
      expect(File.read("#{fs.logs_path}/stdout.log")).to eq "one two three\n"
    end

    it 'sets an environment variable with a single quote character in it' do
      es.set_env('TEST_VAR', "one'two'three")
      es.append_bash_cmd('echo $TEST_VAR')
      es.run
      expect(File.read("#{fs.logs_path}/stdout.log")).to eq "one'two'three\n"
    end
  end

  describe '#prepend_script' do
    let(:fs) { FileSystemMock.new }

    let(:es) { Hive::ExecutionScript.new(
      file_system: fs,
      log: Hive::Log.new,
      keep_running: nil
    ) }

    before(:each) do
      es.instance_variable_set(:@script_lines, ['# line one', '# line two'])
    end

    after(:each) do
      fs.cleanup
    end

    it 'adds a single line to the start of the execution script' do
      es.prepend_bash_cmd('# extra line')
      es.run
      expect(File.read("#{fs.executed_script_path}")).to match /# extra line\n# line one\n# line two$/m
    end

    it 'adds multiple lines to the start of the execution script' do
      es.prepend_bash_cmd('# extra line 1', '# extra line 2', '# extra line 3')
      es.run
      expect(File.read("#{fs.executed_script_path}")).to match /# extra line 1\n# extra line 2\n# extra line 3\n# line one\n# line two$/m
    end
  end

  describe '#append_script' do
    let(:fs) { FileSystemMock.new }

    let(:es) { Hive::ExecutionScript.new(
      file_system: fs,
      log: Hive::Log.new,
      keep_running: nil
    ) }

    before(:each) do
      es.instance_variable_set(:@script_lines, ['# line one', '# line two'])
    end

    after(:each) do
      fs.cleanup
    end

    it 'adds a single line to the start of the execution script' do
      es.append_bash_cmd('# extra line')
      es.run
      expect(File.read("#{fs.executed_script_path}")).to match /# line one\n# line two\n# extra line$/m
    end

    it 'adds multiple lines to the start of the execution script' do
      es.append_bash_cmd('# extra line 1', '# extra line 2', '# extra line 3')
      es.run
      expect(File.read("#{fs.executed_script_path}")).to match /# line one\n# line two\n# extra line 1\n# extra line 2\n# extra line 3$/m
    end
  end
end
