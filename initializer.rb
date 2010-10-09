module UsageTrackerSetup
  ## this function assures that the required couchdb DB is up and running and has a set of basic queries already registered.
  def UsageTrackerSetup.init(couchdb_url)
    puts "db-setup"
    db = CouchRest.database!(couchdb_url)
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
        'by_user_and_timestamp' => {
          'map' => %[
            function (doc) {                                        
              emit ([doc.user_id, doc._id], doc);                                                    
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
          },
	  'user_res_count' => {
	      'map' =>%[ 
	      	 function(doc) {
	    	   if (doc.request_path.indexOf("res/") != -1) {
                     emit([doc.user_id, doc.request_path.split("/")[2]], 1);
                   }
                 }
	      ],
	      'reduce' => %[
	        function(keys, values,rereduce) {
	         return sum(values);
	       }
              ]
	   },
	  'user_area_count' => {
	      'map' =>%[ 
	      	 function(doc) {
		  arr = ['inbox','res','projects','users','account','publish','search']
		  for (i=0;i<arr.length;i++){
	    	    if (doc.request_path.indexOf("/"+arr[i]+"/") != -1) {
		   	area = arr[i]
		    }
		  } 
		  emit([doc.user_id, area], 1);
		}
	      ],
	      'reduce' => %[
	        function(keys, values,rereduce) {
	         return sum(values);
	       }
              ]
	   },
	  'area_count' => {
	      'map' =>%[ 
	      	 function(doc) {
		   arr = ['inbox','res','projects','users','account','publish','search']
		   for (i=0;i<arr.length;i++){
	    	     if (doc.request_path.indexOf("/"+arr[i]+"/") != -1) {
		   	area = arr[i]
		     } 
                   }
		   emit(area, 1);
		 }
	      ],
	      'reduce' => %[
	        function(keys, values,rereduce) {
	         return sum(values);
	       }
              ]
	    },
			'average_duration_of_path' => {
       "map" =>  %[
			    function(doc) {
					  if (doc.duration)
						   emit(doc.request_path, doc.duration);
					}
					],
			    'reduce' =>  %[
					   function(keys,values){
						 		return Math.round(sum(values) / values.length)
						}
					]
				},
			'average_duration_of_area' => {
       "map" =>  %[
			    function(doc) {
		   			arr = ['inbox','res','projects','users','account','publish','search']
		   			for (i=0;i<arr.length;i++){
	    	     	if (doc.request_path.indexOf("/"+arr[i]+"/") != -1) {
		   					area = arr[i]
		     			}
						}	 
					  if (doc.duration)
						   emit(area, doc.duration);
					}
					],
			    'reduce' =>  %[
					   function(keys,values){
						 		return Math.round(sum(values) / values.length)
						}
					]
			}


	 		}
      })
    end
  end
end
