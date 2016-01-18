RepositoryManager.setup do |config|

  # Default repo_item permissions that an object has on the repo_item after a sharing.
  config.default_repo_item_permissions = {
    can_read: true, can_create: false, can_update: false, can_move:false, can_delete:false, can_share: false
  }

  # Default sharing permissions that an object has when he is added in a sharing.
  config.default_sharing_permissions = { can_add: false, can_remove: false }

  # Default path for generating the zip file when a user want to download a folder
  # WARNING: DO NOT CHANGE IF YOU DON'T KNOW WHAT YOU ARE DOING
  # Default is : "download/#{member.class.to_s.underscore}/#{member.id}/#{self.class.to_s.underscore}/#{self.id}/"
  #config.default_zip_path = true

  # Define if we enable or not the versioning on the repo_item
  config.has_paper_trail = false

  # Define if a repo item with the same name will be automaticaly overwrited when a new item is create
  config.auto_overwrite_item = false
end