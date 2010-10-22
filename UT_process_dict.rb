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
   # takes only the ids of the elements
   # for the polymorph model <asset> also the type is registered
   def self.shape_data(data)
      data.each do |k,v|
        if k == :assets 
          if v
            data[k] = v.map do |it| 
              if it.class == NetworkAsset
                {:id => it.content_id, :type=>it.content_type} 
              else
                {:id => it.id, :type => it.class.name} 
              end
            end
          end  
        else
          data[k] = v.map{|it| it.id} if v
        end
      end
      data
   end

end
