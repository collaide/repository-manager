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
  s.description = "Repository Manager help you to easily manage your files and folders. Each instance has its own repository. You can share these items with other instance with a complet flexible permission control. "

  #s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  #s.test_files = Dir["spec/**/*"]
  s.license = 'MIT'

  s.add_runtime_dependency('rails', '> 3.0.0')

  s.add_development_dependency('factory_girl', '>= 2.6.0')
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency('rspec-rails', '>= 2.6.1')
  s.add_runtime_dependency 'ancestry'
  s.add_runtime_dependency('carrierwave', '>= 0.5.8')
  s.add_runtime_dependency 'rubyzip', '>= 1.0.0'#, :require => 'zip/zip'
end
