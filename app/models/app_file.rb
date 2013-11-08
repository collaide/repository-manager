class AppFile < Repository

  mount_uploader :name, RepositoryUploader

  before_save :update_asset_attributes

  private

  def update_asset_attributes
    if name.present? && name_changed?
      self.content_type = name.file.content_type
      self.file_size = name.file.size
    end
  end

end
