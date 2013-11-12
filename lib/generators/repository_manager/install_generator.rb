module RepositoryManager #:nodoc:
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    source_root File.expand_path("../templates", __FILE__)
    require 'rails/generators/migration'

    def self.next_migration_number path
      unless @prev_migration_nr
        @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
      else
        @prev_migration_nr += 1
      end
      @prev_migration_nr.to_s
    end

    def create_initializer_file
      template 'initializer.rb', 'config/initializers/repository_manager.rb'
    end

    # all public methods in here will be run in order
    #def copy_initializer_file
    #  copy_file "initializer.rb", "config/initializers/repository_manager_initializer.rb"
    #end

    def copy_migrations
      migrations = [["20131018214212_create_repository_manager.rb","create_repository_manager.rb"],
                    ["20131025085844_add_file_to_repositories.rb","add_file_to_repositories.rb"],
                    ["20131025085845_add_file_to_files", "add_file_to_files.rb"]
                    ]
      migrations.each do |migration|
        migration_template "../../../../db/migrate/" + migration[0], "db/migrate/" + migration[1]
      end
    end
  end
end