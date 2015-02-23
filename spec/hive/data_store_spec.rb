require 'spec_helper'
require 'hive/data_store'

describe Hive::DataStore do
  describe '#initialize' do
    it 'creates an sqlite3 database file if it does not already exist' do
      file = Tempfile.new('sqlite3')
      ds = Hive::DataStore.new(file.path)
      expect(File).to exist(file.path)
      file.unlink
    end
  end
end
