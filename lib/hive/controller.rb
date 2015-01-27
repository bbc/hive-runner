require 'hive'

module Hive
  # Generic hive controller class
  class Controller
    attr_reader :workers
    attr_reader :type

    def initialize(config)
      @config = {
        'max_workers' => 0
      }.merge(config)
      @workers = []
      @type ||= 'undefined'
      require "hive/worker/#{@type}"
    end

    def check_workers
      (1..(@config['max_workers'] - @workers.length)).each do
        @workers << Object.const_get('Hive').const_get('Worker').const_get(@type.capitalize).new(@config)
      end
    end
  end
end
