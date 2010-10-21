# encapsulates calls to Thread.current 
# called from the network search controller in order to track search results
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
   ## takes only the ids of the elements, only for polymorph model <asset> the type is registered
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
