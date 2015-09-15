
module Hive
  class Results
    attr_reader :timestamp
    def initialize( state, message, data = {})
      @state = state
      @message = message
      @data = data  
      @timestamp = Time.now
    end
  
    def failed?
      @state == 'fail'
    end

    def passed?
      @state == 'pass'
    end
  end
end