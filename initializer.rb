require 'erb'

module UsageTrackerSetup
  ## this function assures that the required couchdb DB is up and running and has a set of basic queries already registered.
  def UsageTrackerSetup.init(couchdb_url)
    db = CouchRest.database!(couchdb_url) #FIXME

    new = YAML.load(ERB.new(File.read('extras/usage_tracker/views.yml')).result)
    id  = new['_id']
    old = db.get id rescue nil

    if old.nil?
      puts "** Creating Design Document #{id} v#{new['version']}"
      db.save_doc new

    elsif old['version'].to_i < new['version'].to_i
      puts "** Upgrading Design Document #{id} to v#{new['version']}"
      db.delete_doc old
      db.save_doc new
    end

  end
end
