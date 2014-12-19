require 'hive'

module Hive
  class Controller
    def initialize(config)
      @config = config
      @workers = []
    end
  end
end
