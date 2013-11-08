module RepositoryManager #:nodoc:
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    # all public methods in here will be run in order
    #def copy_initializer_file
    #  copy_file "initializer.rb", "config/initializers/repository_manager_initializer.rb"
    #end

    def copy_migrations
      migrations = [["20131018214212_create_repository_manager.rb","create_repository_manager.rb"],
                    ["20131025085844_add_file_to_repositories.rb","add_file_to_repositories.rb"]
                    ]
      migrations.each do |migration|
        copy_file "../../../../db/migrate/" + migration[0], "db/migrate/" + migration[1]
      end
    end
  end
end