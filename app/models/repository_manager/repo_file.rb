class RepositoryManager::RepoFile < RepositoryManager::RepoItem
  attr_accessible :file, :content_type, :file_size if RepositoryManager.protected_attributes?

  validates_presence_of :file
  mount_uploader :file, RepoFileUploader
  before_save :update_asset_attributes

  # Return the name of the file with his extension
  def name
    file.url.split('/').last
  end

  def download(options = {})
    self.download!(options)
  end

  # Downloading this file
  def download!(options = {})
    file.path
  end

  # Copy itself into the source_folder
  # options
  #   :source_folder = the folder in witch you copy this item
  #   :owner = the owner of the item
  #   :sender = the sender of the item (if you don't specify sender.. The sender is still the same)
  def copy!(options = {})
    new_item = RepositoryManager::RepoFile.new
    new_item.file = File.open(self.file.current_path)

    if options[:source_folder]
      options[:source_folder].add!(new_item)
    elsif options[:owner].repo_item_name_exist_in_root?(new_item.name)
      raise RepositoryManager::RepositoryManagerException.new("copy failed. The repo_file '#{new_item.name}' already exist in root.")
    end

    options[:owner] ? new_item.owner = options[:owner] : new_item.owner = self.owner
    if options[:sender]
      new_item.sender = options[:sender]
      #elsif options[:owner]
      #  new_item.sender = options[:owner]
    else
      new_item.sender = self.sender
    end

    new_item.save!
    new_item
  end

  def copy(options = {})
    begin
      copy!(options)
    rescue RepositoryManager::PermissionException, RepositoryManager::RepositoryManagerException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      false
    end
  end

  private

  def update_asset_attributes
    if file.present? && file_changed?
      self.content_type = file.file.content_type
      self.file_size = file.file.size
    end
  end

end
