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
  s.summary     = "Ruby on Rails plugin (gem) for managing repositories (files/folders/permissions/sharings)."
  s.description = "This project is based on the need for a repository manager system for Collaide. A system for easily create/delete files and folders in a repository. For sharing these repositories easily with other object with a flexible and complete authorisations management.
Each instance (users, groups, etc..) can have it own repositories (with files and folders). It can manage them easily (edit, remove, add, etc) and sharing them with other instance."

  #s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  #s.test_files = Dir["spec/**/*"]
  s.license = 'MIT'

  s.add_runtime_dependency 'rails', '~> 3.0.0'

  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec-rails', '~> 2.0'
  s.add_runtime_dependency 'ancestry'
  s.add_runtime_dependency 'carrierwave'
  s.add_runtime_dependency 'rubyzip'#, '< 1.0.0'#, :require => 'zip/zip'
end