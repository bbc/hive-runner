module Hive
  class Results
    attr_reader :timestamp
    def initialize( state, message, data = {}, hive_mind)
      @state = state
      @message = message
      @data = data  
      @timestamp = Time.now
      @hive_mind = hive_mind
      submit_results
    end
  
    def failed?
      @state == 'fail'
    end

    def passed?
      @state == 'pass'
    end

    def formulate_results
       result = []
       h = {}
       @data.each do |k,v|
         h[:label] = k.to_s
         h[:unit] = v[:unit] || nil
         if v[:value].instance_of?(Time)
           h[:value] = v[:value].to_i
           h[:format] = 'timestamp'
         else
           h[:value] = v[:value]
           h[:format] = 'integer'
         end
         result << h
         h = {}
       end
       result
    end

    def submit_results
       @hive_mind.add_statistics(formulate_results)
       @hive_mind.flush_statistics
    end

  end
end
