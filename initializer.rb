module UsageTrackerSetup
  ## this function assures that the required couchdb DB is up and running and has a set of basic queries already registered.
  def UsageTrackerSetup.init(couchdb_url)
    puts "db-setup"
    db = CouchRest.database!(couchdb_url) #FIXME
    begin
      db.get('_design/basic')
    rescue
      db.save_doc(YAML.load_file('extras/usage_tracker/views.yml'))
    end
  end
end
