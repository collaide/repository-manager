class RepositoryManager::RepoFile < RepositoryManager::RepoItem
  # attr_accessible :file, :content_type, :file_size, :checksum if RepositoryManager.protected_attributes?

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
    file.url
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

  # Unzip the compressed file and create the repo_items
  # options
  #   :source_folder = the folder in witch you unzip this archive
  #   :owner = the owner of the item
  #   :sender = the sender of the item (if you don't specify sender.. The sender is still the same)
  #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')
  def unzip!(options = {})
    !!options[:overwrite] == options[:overwrite] ? overwrite = options[:overwrite] : overwrite = RepositoryManager.auto_overwrite_item
    options[:owner] ? owner = options[:owner] : owner = self.owner
    options[:sender] ? sender = options[:sender] : sender = self.sender

    Zip::File.open(self.file.path) do |zip_file|
      # This hash make the link between the path and the item (if it exist)
      #link_path_item = {}

      # Handle entries one by one
      zip_file.each do |entry|
        array_name = entry.name.split('/')
        name = array_name[-1]
        path_array = array_name.first(array_name.size - 1)
        #name.parameterize.underscore

        #it is a folder
        if entry.ftype == :directory

          new_item = RepositoryManager::RepoFolder.new(name: name)
          new_item.owner = owner
          new_item.sender = sender
          if path_array.empty?
            new_item.move!(source_folder: options[:source_folder], owner: owner, sender: sender, overwrite: overwrite)
          else
            # He specified a source_folder
            if options[:source_folder]
              source_folder = options[:source_folder].get_or_create_by_path_array(path_array, owner: owner, sender: sender)
            else # No source folder specified
              # We have to check if we are in a folder
              parent = self.parent
              if parent
                # we unzip on this folder
                source_folder = parent.get_or_create_by_path_array(path_array, owner: owner, sender: sender)
              else
                # We are in root
                source_folder = owner.get_or_create_by_path_array(path_array, sender: sender)
              end
            end
            new_item.move!(source_folder: source_folder, owner: owner, sender: sender, overwrite: overwrite)
          end
        else # it is a :file
          new_item = RepositoryManager::RepoFile.new
          new_item.name = name
          new_item.sender = sender
          new_item.owner = owner

          tmp_file_path = File.join(Rails.root, 'tmp', 'unzip', name)
          # Delete the path
          FileUtils.rm_rf(tmp_file_path)
          entry.extract(tmp_file_path)
          new_item.file = File.open(tmp_file_path)


          if path_array.empty?
            new_item.move!(source_folder: options[:source_folder], owner: owner, sender: sender, overwrite: overwrite)
          else
            # He specified a source_folder
            if options[:source_folder]
              source_folder = options[:source_folder].get_or_create_by_path_array(path_array, owner: owner, sender: sender)
            else # No source folder specified
              # We have to check if we are in a folder
              parent = self.parent
              if parent
                # we unzip on this folder
                source_folder = parent.get_or_create_by_path_array(path_array, owner: owner, sender: sender)
              else
                # We are in root
                source_folder = owner.get_or_create_by_path_array(path_array, owner: owner, sender: sender)
              end
            end
            new_item.move!(source_folder: source_folder, owner: owner, sender: sender, overwrite: overwrite)
          end
        end
      end

    end
    self
  end

  private


  def repo_file_params
    params.require(:repo_file).permit(:file, :content_type, :file_size)
  end

  def update_asset_attributes
    if file.present? && file_changed?
      self.content_type = file.file.content_type
      self.file_size = file.file.size
      # self.checksum = Digest::MD5.file(file.path).hexdigest

      # self.attributes = {
      #   content_type: file.file.content_type ,
      #   file_size: file.file.size ,
      #   checksum:  Digest::MD5.file(file.path).hexdigest
      #  }

      # self.update_attribute(:content_type, file.file.content_type)
      # self.update_attribute(:file_size, file.file.size)
      # self.update_attribute(:checksum, Digest::MD5.file(file.path).hexdigest)
    end
  end

  def default_name
    if name.blank?
      self.name = file.url.split('/').last
    end
  end

end
