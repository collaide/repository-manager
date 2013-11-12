require 'repository_manager/has_repository'

module RepositoryManager

  mattr_accessor :default_repo_permissions
  @@default_repo_permissions = { can_read: true, can_create: false, can_update:false, can_delete:false, can_share: false }

  mattr_accessor :default_share_permissions
  @@default_share_permissions = { can_add: false, can_remove: false }

  class << self
    def setup
      yield self
    end

    def protected_attributes?
      Rails.version < '4' || defined?(ProtectedAttributes)
    end
  end

end

require 'repository_manager/engine'