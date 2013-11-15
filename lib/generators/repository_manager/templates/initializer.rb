RepositoryManager.setup do |config|

  # Default repo_item permissions that an object has on the repo_item after a sharing.
  config.default_repo_item_permissions = { can_read: true, can_create: false, can_update:false, can_delete:false, can_share: false }

  # Default sharing permissions that an object has when he is added in a sharing.
  config.default_sharing_permissions = { can_add: false, can_remove: false }
end