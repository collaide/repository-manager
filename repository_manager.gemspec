$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "repository_manager/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'repository-manager'
  s.version     = RepositoryManager::VERSION
  s.authors     = ['Yves Baumann']
  s.email       = ['texicitys@gmail.com']
  s.homepage    = 'https://github.com/Texicitys/repository-manager'
  s.summary     = "Ruby on Rails plugin (gem) for managing repositories (files/folders/permissions/shares)."
  s.description = "This project is based on the need for a repository manager system for Collaide. Instead of creating my core repository manager system heavily dependent on our development, I'm trying to implement a generic and potent repository gem.
                    After looking for a good gem to use I noticed the lack of repository gems and flexibility in them. RepositoryManager tries to be the more flexible possible. Each instance (users, groups, etc..) can have it own repositories (with files and folders). It can manage them easily (edit, remove, add, etc) and share them with other instance.
                    This gem is my informatics project for the Master in University of Lausanne (CH)."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]
  s.license = 'MIT'

  s.add_dependency 'rails', '> 3.0.0'

  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec-rails', '~> 2.0'
  s.add_development_dependency 'ancestry'
  s.add_development_dependency 'carrierwave'
  s.add_development_dependency 'enumerize'
end