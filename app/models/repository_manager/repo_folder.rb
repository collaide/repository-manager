require 'zip'

class RepositoryManager::RepoFolder < RepositoryManager::RepoItem

  validates :name, presence: true

  # Get or create the folder with this name
  # options
  #   :owner = you can path an owner (you have to if you have no :source_folder)
  #   :sender = the sender of the item
  def get_or_create_by_path_array(path_array, options = {})
    child = self
    unless path_array.empty?
      name = path_array[0]
      child = self.get_child_by_name(name)
      unless child
        child = options[:owner].create_folder(name, source_folder: self)
        if options[:sender]
          child.sender = options[:sender]
          child.save!
        end
      end
      # remove the first element
      path_array.shift
      child = child.get_or_create_by_path_array(path_array, options)
    end
    child
  end

  # Get a child item based on path provided
  def get_by_path_array(path_array)
    child = self
    unless path_array.empty?
      name = path_array[0]
      child = self.get_child_by_name(name)

      # remove the first element
      path_array.shift
      child = child.get_by_path_array(path_array) if child
    end
    child
  end

  # Add a repo_item in the folder.
  # options
  #   :destroy_if_fail = false // the repo_item if it can't move it.
  #   :do_not_save = false // Save the repo_item after changing his param
  #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')
  # second param destroy the repo_item if it can't move it.
  def add!(repo_item, options = {})
    !!options[:overwrite] == options[:overwrite] ? overwrite = options[:overwrite] : overwrite = RepositoryManager.auto_overwrite_folder
    repo_item.move!(source_folder: self, do_not_save: options[:do_not_save], destroy_if_fail: options[:destroy_if_fail], overwrite: overwrite, owner: options[:owner])
  end

  def add(repo_item)
    begin
      add!(repo_item)
    rescue RepositoryManager::ItemExistException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      false
    end
  end

  # Copy itself into the source_folder
  # options
  #   :source_folder = the folder in witch you copy this item
  #   :owner = the owner of the item
  #   :sender = the sender of the item (if you don't specify sender.. The sender is still the same)
  #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')
  def copy!(options = {})
    !!options[:overwrite] == options[:overwrite] ? overwrite = options[:overwrite] : overwrite = RepositoryManager.auto_overwrite_item

    new_item = RepositoryManager::RepoFolder.new
    new_item.name = self.name

    options[:owner] ? new_item.owner = options[:owner] : new_item.owner = self.owner
    options[:sender] ? new_item.sender = options[:sender] : new_item.sender = self.sender

    if options[:source_folder]
      options[:source_folder].add!(new_item, do_not_save: true)
    elsif options[:owner]
      repo_item_with_same_name = options[:owner].get_item_in_root_by_name(new_item.name)
      if repo_item_with_same_name and !overwrite
        self.errors.add(:copy, I18n.t('repository_manager.errors.repo_item.item_exist'))
        raise RepositoryManager::ItemExistException.new("copy failed. The repo_folder '#{new_item.name}' already exist in root.")
      elsif repo_item_with_same_name and overwrite
        repo_item_with_same_name.destroy!
      end
    else
      repo_item_with_same_name = self.owner.get_item_in_root_by_name(new_item.name)
      if repo_item_with_same_name and !overwrite
        self.errors.add(:copy, I18n.t('repository_manager.errors.repo_item.item_exist'))
        raise RepositoryManager::ItemExistException.new("copy failed. The repo_file '#{new_item.name}' already exist in root.")
      elsif repo_item_with_same_name and overwrite
        repo_item_with_same_name.destroy!
      end
    end

    new_item.save

    # Recursive method which copy all children.
    children.each do |c|
      c.copy!(source_folder: new_item, owner: options[:owner], sender: options[:sender], overwrite: overwrite)
    end

    new_item
  end

  def copy(options = {})
    begin
      copy!(options)
    rescue RepositoryManager::ItemExistException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      false
    end
  end

    # Download this folder (zip it first)
  # Return the path to the folder.zip
  # options can have :
  #     :object => Object : is the object that request the download
  #         If object = nil, it download all the folder
  #         if object is set, it download only the folder that the object `can_read`.
  #     :path => 'path/to/zip/' is the path where the zip is generated
  def download!(options = {})
    # Get all the children
    children = self.children

    # If something is in the array to add, we zip it
    #if children.length > 0

      # Default values
      options[:object]? object = options[:object]: object = nil

      RepositoryManager.default_zip_path == true ? path = get_default_download_path(object): path = RepositoryManager.default_zip_path
      path = options[:path] if options[:path]

      full_path = "#{path}#{name}.zip"

        # Create the directory if not exist
        dir = File.dirname(full_path)
        unless File.directory?(dir)
          FileUtils.mkdir_p(dir)
        end
      # Delete the zip if it already exist
      File.delete(full_path) if File.exist?(full_path)

      Zip::File.open(full_path, Zip::File::CREATE) { |zf|
        add_repo_item_to_zip(children, zf, object)
      }

    File.chmod(0444, full_path)

    return full_path
    #else
    #  # Nothing to download here
    #  raise RepositoryManager::RepositoryManagerException.new("download failed. Folder #{name} is empty")
    #end
  end

  def download(options = {})
    begin
      download!(options)
    rescue RepositoryManager::RepositoryManagerException
      false
    end
  end


    # Delete the zip file
  def delete_zip(options = {})
    options[:object]? object = options[:object]: object = nil
    RepositoryManager.default_zip_path == true ? path = get_default_download_path(object): path = RepositoryManager.default_zip_path
    path = options[:path] if options[:path]

    # Delete the path
    FileUtils.rm_rf(path)
  end

  # Returns true or false if the name exist in this folder
  def name_exist_in_children?(name)
    #RepositoryManager::RepoItem.where(name: name).where(id: child_ids).first ? true : false
    get_child_by_name(name) ? true : false
  end

  def get_child_by_name(name)
    self.children.where(name: name).take
    # RepositoryManager::RepoItem.where('name = ?', name).where(id: child_ids).first
  end

  private
  # Returns the default path of the zip file
  # object is the object that want to download this file
  def get_default_download_path(object = nil)
    object ? add_to_path = object.get_default_download_path(''): add_to_path = ''
    "#{Rails.root.join('download')}/#{add_to_path}#{self.class.base_class.to_s.underscore}/#{self.id}/"
  end

  def add_repo_item_to_zip(children, zf, object = nil, prefix = nil)
    children.each do |child|
      # If this is a file, we just add this file to the zip
      if child.is_file?
        # Add the file in the zip if the object is authorised to read it.
        zf.add("#{prefix}#{child.name}", child.file.current_path) if object == nil || !RepositoryManager.accept_nested_sharing || object.can_read?(child)
      elsif child.is_folder?
        children = child.children
        # If this folder has children, we do it again with it children
        if children.empty?
          # We just create the folder if it is empty
          zf.mkdir("#{prefix}#{child.name}") if object == nil || !RepositoryManager.accept_nested_sharing || object.can_read?(child)
        else
          # We go in this new directory and add it repo_items
          add_repo_item_to_zip(child.children, zf, object, "#{prefix}#{child.name}/")
        end
      end
    end
  end
end
