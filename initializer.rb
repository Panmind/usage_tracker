module UsageTrackerSetup
  def UsageTrackerSetup.init()
    puts "db-setup"
    db = CouchRest.database!("localhost:5984/pm_usage")
    view = db.get('_design/basic') rescue nil
    if view.nil?
      db.save_doc({
      '_id'   => '_design/basic',
      'language' => "javascript",
      'views' => {
        'by_user_and_timestamp' => {
          'map' => %[
            function (doc) {                                        
              emit ([doc.user_id, doc._id], doc);                                                    
            }
          ]                                                        
        },
        'by_timestamp_and_user' => {
          'map' => %[
            function (doc) {                                        
              emit ([doc._id, doc.user_id], doc);                                                    
            }
          ]
        },
        'res_count' => {
	  'map' => %[
	    function(doc) {
	  	if (doc.request_path.indexOf("res/") != -1){
                    emit(doc.request_path.split("/")[2], 1);
		}
            }
          ],
	  'reduce' => %[
	      function(keys, values,rereduce) {
	         return sum(values);
	      }
	  ]
          },
	  'res_item_count' => {
	      'map' =>%[ 
	      	 function(doc) {
	    	   if (doc.request_path.indexOf("res/") != -1 & 
		       doc.request_path.split("/").length > 3) {
                     emit([doc.request_path.split("/")[2],doc.request_path.split("/")[3]], 1);
                   }
                 }
	      ],
	  'reduce' => %[
	      function(keys, values,rereduce) {
	         return sum(values);
	      }
          ]
          }
	}
      })
    end
  end
end
