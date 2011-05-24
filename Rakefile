# -*- encoding: utf-8 -*-
#
require 'rake'
require 'rake/rdoctask'

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = 'panmind-usage-tracker'
    gemspec.summary     = 'Write your application request logs on CouchDB or MongoDB'
    gemspec.description = 'This software implements a Rails 3 Middleware and ' \
                          'an EventMachine reactor to store into a database the ' \
                          'results of HTTP request processing'

    gemspec.authors     = ['Marcello Barnaba', 'Christian Wörner', 'Fabrizio Regini']
    gemspec.homepage    = 'http://github.com/Panmind/usage_tracker'
    gemspec.email       = 'info@panmind.org'

    gemspec.add_dependency('rails', '~> 3.0')
    gemspec.add_dependency('eventmachine')
    gemspec.add_dependency('couchrest')
    gemspec.add_dependency('mongo')
    gemspec.add_dependency('bson')
    gemspec.add_dependency('bson_ext')
  end
rescue LoadError
  puts 'Jeweler not available. Install it with: gem install jeweler'
end

desc 'Generate the rdoc'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.add %w( README.md lib/**/*.rb )

  rdoc.main  = 'README.md'
  rdoc.title = 'Rails Application Usage Tracker'
end

desc 'Will someone help write tests?'
task :default do
  puts
  puts 'Can you help in writing tests? Please do :-)'
  puts
end
