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
    path = file.path
  end

  private

  def update_asset_attributes
    if file.present? && file_changed?
      self.content_type = file.file.content_type
      self.file_size = file.file.size
    end
  end

end
