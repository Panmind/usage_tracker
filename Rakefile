# -*- encoding: utf-8 -*-
#
require 'rake'
require 'rake/rdoctask'

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name        = 'panmind-usage-tracker'
    gemspec.summary     = 'Write your application request logs in CouchDB'
    gemspec.description = 'This software implements a Rails 3 Middleware and ' \
                          'an EventMachine reactor to store into CouchDB the ' \
                          'results of HTTP request processing'

    gemspec.authors     = ['Marcello Barnaba', 'Christian Wörner']
    gemspec.homepage    = 'http://github.com/Panmind/usage_tracker'
    gemspec.email       = 'vjt@openssl.it'

    gemspec.add_dependency('rails', '~> 3.0')
    gemspec.add_dependency('eventmachine')
    gemspec.add_dependency('couchrest')
  end
rescue LoadError
  puts 'Jeweler not available. Install it with: gem install jeweler'
end

desc 'Generate the rdoc'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.add %w( README.md lib/**/*.rb )

  rdoc.main  = 'README.md'
  rdoc.title = 'Rails Application Usage Tracker on CouchDB'
end

desc 'Will someone help write tests?'
task :default do
  puts
  puts 'Can you help in writing tests? Please do :-)'
  puts
end

