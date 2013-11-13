RepositoryManager.setup do |config|

  # Default repository permissions that an object has on the repository after a share.
  config.default_repo_permissions = { can_read: true, can_create: false, can_update:false, can_delete:false, can_share: false }

  # Default share permissions that an object has when he is added in a share.
  config.default_share_permissions = { can_add: false, can_remove: false }
end