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
  s.summary     = "Ruby on Rails plugin (gem) for managing repositories ( files / folders / permissions / sharings )."
  #s.description = "Repository Manager help you to easily manage your files and folders. Each instance has its own repository. You can share these items with other instance with a complet flexible permission control. "
  s.description = "This project is based on the need for a system for easily create/delete files and folders in a repository. For sharing these repositories easily with other object with a flexible and complete permissions management. Each instance (users, groups, etc..) can have it own repositories (with files and folders). It can manage them easily (create, delete, edit, move, copy, etc) and sharing them with other instance."

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")

  s.license = 'MIT'

  s.add_runtime_dependency('rails', '~> 5.1.0')

  # s.add_development_dependency('factory_bot', '>= 2.6.0')
  s.add_development_dependency('factory_bot', '~> 4.7.0')
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency('rspec-rails', '~> 2.6.1')
  s.add_development_dependency('spork')
  s.add_development_dependency('byebug')
  s.add_runtime_dependency 'ancestry'
  # s.add_runtime_dependency('carrierwave', '>= 0.5.8')
  s.add_runtime_dependency('carrierwave', '~> 1.2.0')
  s.add_runtime_dependency 'rubyzip', '~> 1.0.0'#, :require => 'zip/zip'
  # s.add_runtime_dependency 'paper_trail', '~> 3.0.1'
  s.add_runtime_dependency 'paper_trail', '~> 5.2.0'
end
