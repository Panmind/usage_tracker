class UTProcessDict
    def self.set_search_result(data)
      data = shape_data(data)
      Thread.current[:ut_search_result] = data
    end
    # reads the search result and cleans the Thread hash
    def self.get_search_result
      res = Thread.current[:ut_search_result]
      Thread.current[:ut_search_result] = nil
      res
   end
   private
   ## XXX -> ID should be enough (for polymorph types the type should be noted as well.....)
   def self.shape_data(data)
      data.each do |k,v|
        if k == :assets 
          data[k] = v.map{|it| {:id => it.content_id,:type=>it.content_type}}
        else
          data[k] = v.map{|it| it.id}
        end
      end
      data
   end

end
