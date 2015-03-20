require 'active_record'
require 'hive/data_store/port'

module Hive
  class DataStore
    # Initialize the database connection
    def initialize(filename)
      Hive.logger.info("Connecting to database #{filename}")
      ActiveRecord::Base.establish_connection(
        adapter: :sqlite3,
        database: filename,
        timeout: 200
      )

      # Create tables if they do not already exist
      if ! ActiveRecord::Base.connection.table_exists? 'ports'
        Hive.logger.info("Creating 'ports' table in database")
        ActiveRecord::Schema.define do
          create_table :ports do |table|
            table.column :port, :integer
            table.column :worker, :string, default: nil
          end
        end
      end
    end

    def port
      Hive::DataStore::Port
    end
  end
end
