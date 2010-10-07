module UsageTrackerSetup
  def UsageTrackerSetup.init()
    puts "db-setup"
    db = CouchRest.database!("localhost:5984/pm_usage")
    puts "re-initializing"
    view = db.get('_design/basic') rescue nil
    if view.nil?
      db.save_doc({
      '_id'   => '_design/basic',
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
        }
      }
      })
    end
  end
end
