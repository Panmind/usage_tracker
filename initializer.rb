require 'erb'

module UsageTrackerSetup
  ## this function assures that the required couchdb DB is up and running and has a set of basic queries already registered.
  def UsageTrackerSetup.init(couchdb_url)
    db = CouchRest.database!(couchdb_url) #FIXME
    db.get('_design/basic')
  rescue RestClient::ResourceNotFound
    db.save_doc YAML.load(ERB.new(File.read('extras/usage_tracker/views.yml')).result)
  end
end
