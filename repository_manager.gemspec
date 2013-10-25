$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "repository_manager/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "repository_manager"
  s.version     = RepositoryManager::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = 'https://github.com/Texicitys/Repository-Manager'
  s.summary     = "TODO: Summary of RepositoryManager."
  s.description = "TODO: Description of RepositoryManager."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.0.0"

  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec-rails', '~> 2.0'
  s.add_development_dependency 'ancestry'
  s.add_development_dependency 'carrierwave'
  s.add_development_dependency 'enumerize'
end