require 'active_record'

module Hive
  class DataStore
    # Initialize the database connection
    def initialize(filename)
      ActiveRecord::Base.establish_connection(
        adapter: :sqlite3,
        database: filename
      )

      # Create tables if they do not already exist
      if ! ActiveRecord::Base.connection.table_exists? 'ports'
        ActiveRecord::Schema.define do
          create_table :ports do |table|
            table.column :port, :integer
            table.column :worker, :string, default: nil
          end
        end
      end
    end
  end
end
