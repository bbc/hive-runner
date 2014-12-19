require 'hive/controller'
require 'hive/worker/shell'

module Hive
  class Controller::Shell < Controller
    def step
      (1..(@config['max_workers'] - @workers.length)).each do
        @workers << Hive::Worker::Shell.new
      end
    end
  end
end
