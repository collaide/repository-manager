class RepoFile < RepoItem
  attr_accessible :file, :content_type, :file_size if RepositoryManager.protected_attributes?

  validates :file, presence: true
  mount_uploader :file, RepoFileUploader
  before_save :update_asset_attributes

  # Return the name of the file with his extension
  def name
    file.url.split('/').last
  end

  # Downloading this file
  def download(options = {})
    path = file.path
    #render status: :bad_request and return unless File.exist?(path)
    #send_file(path)
  end

  private

  def update_asset_attributes
    if file.present? && file_changed?
      self.content_type = file.file.content_type
      self.file_size = file.file.size
    end
  end

end
