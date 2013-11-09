begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :test => :spec
task :default => :spec

# Documentation
RDoc::Task.new :rdoc do |rdoc|
  rdoc.main = 'README.md'

  rdoc.rdoc_files.include('README.md', 'app/**/*.rb', 'lib/*.rb', 'lib/repository_manager/*.rb')
  #change above to fit needs

  rdoc.title = 'RepositoryManager Documentation'
  rdoc.options << '--all'
end