class RepositoryManager::RepoFile < RepositoryManager::RepoItem
  attr_accessible :file, :content_type, :file_size, :checksum if RepositoryManager.protected_attributes?

  validates_presence_of :file
  mount_uploader :file, RepoFileUploader
  before_save :update_asset_attributes
  before_create :default_name

  ## Return the name of the file with his extension
  #def name
  #  if self.name.blank?
  #    file.url.split('/').last
  #  else
  #    self.name
  #  end
  #end

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
  #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')
  def copy!(options = {})
    !!options[:overwrite] == options[:overwrite] ? overwrite = options[:overwrite] : overwrite = RepositoryManager.auto_overwrite_item

    new_item = RepositoryManager::RepoFile.new
    new_item.file = File.open(self.file.current_path)
    new_item.name = self.name

    options[:owner] ? new_item.owner = options[:owner] : new_item.owner = self.owner
    options[:sender] ? new_item.sender = options[:sender] : new_item.sender = self.sender

    if options[:source_folder]
      new_item = options[:source_folder].add!(new_item, do_not_save: true, overwrite: overwrite )
    elsif options[:owner]
      repo_item_with_same_name = options[:owner].get_item_in_root_by_name(new_item.name)
      if repo_item_with_same_name and !overwrite
        self.errors.add(:copy, I18n.t('repository_manager.errors.repo_item.item_exist'))
        raise RepositoryManager::ItemExistException.new("copy failed. The repo_file '#{new_item.name}' already exist in root.")
      elsif repo_item_with_same_name and overwrite
        repo_item_with_same_name.file = new_item.file
        repo_item_with_same_name.sender = new_item.sender
        new_item = repo_item_with_same_name
      end
    else
      repo_item_with_same_name = self.owner.get_item_in_root_by_name(new_item.name)
      if repo_item_with_same_name and !overwrite
        self.errors.add(:copy, I18n.t('repository_manager.errors.repo_item.item_exist'))
        raise RepositoryManager::ItemExistException.new("copy failed. The repo_file '#{new_item.name}' already exist in root.")
      elsif repo_item_with_same_name and overwrite
        repo_item_with_same_name.file = new_item.file
        repo_item_with_same_name.sender = new_item.sender
        new_item = repo_item_with_same_name
      end
    end

    new_item.save!
    new_item
  end

  def copy(options = {})
    begin
      copy!(options)
    rescue RepositoryManager::ItemExistException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      false
    end
  end

  private

  def update_asset_attributes
    if file.present? && file_changed?
      self.content_type = file.file.content_type
      self.file_size = file.file.size
      self.checksum = Digest::MD5.file(file.path).hexdigest
    end
  end

  def default_name
    if name.blank?
      self.name = file.url.split('/').last
    end
  end

end
