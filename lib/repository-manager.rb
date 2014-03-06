require 'repository_manager/has_repository'

module RepositoryManager

  mattr_accessor :default_repo_item_permissions
  @@default_repo_item_permissions = { can_read: true, can_create: false, can_update:false, can_delete:false, can_share: false }

  mattr_accessor :default_sharing_permissions
  @@default_sharing_permissions = { can_add: false, can_remove: false }

  mattr_accessor :default_zip_path
  @@default_zip_path = true

  mattr_accessor :accept_nested_sharing
  @@accept_nested_share = false

  #mattr_accessor :user_model
  ##@@user_model = 'User'
  #@@user_model = false

  class << self
    def setup
      yield self
    end

    def protected_attributes?
      Rails.version < '4' || defined?(ProtectedAttributes)
    end

    ##
    # Loads the Carrierwave locale files before the Rails application locales
    # letting the Rails application overrite the carrierwave locale defaults
    #config.before_configuration do
      I18n.load_path << File.join(File.dirname(__FILE__), 'repository_manager', 'locales', 'repository_manager.en.yml')
    #end

  end

end

require 'repository_manager/engine'
require 'repository_manager/exceptions'