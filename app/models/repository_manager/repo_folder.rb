require 'zip'

class RepositoryManager::RepoFolder < RepositoryManager::RepoItem

  validates :name, presence: true

  # Add a repo_item in the folder.
  # second param destroy the repo_item if it can move it.
  def add!(repo_item, destroy_if_fail = false)
    # We check if this name already exist
    #if repo_item.children.exists?(:name => repo_item.name)
    if name_exist_in_children?(repo_item.name)
      # we delete the repo if asked
      repo_item.destroy if destroy_if_fail
      raise RepositoryManager::ItemExistException.new("add failed. The repo_item '#{repo_item.name}' already exist in the folder '#{name}'")
    else
      repo_item.update_attribute :parent, self
    end
  end

  def add(repo_item)
    begin
      add!(repo_item)
    rescue RepositoryManager::ItemExistException
      false
    end
  end

  # Copy itself into the source_folder
  # options
  #   :source_folder = the folder in witch you copy this item
  #   :owner = the owner of the item
  #   :sender = the sender of the item (if you don't specify sender.. The sender is still the same)
  def copy!(options = {})
    new_item = RepositoryManager::RepoFolder.new
    new_item.name = self.name

    if options[:source_folder]
      options[:source_folder].add!(new_item)
    elsif options[:owner].repo_item_name_exist_in_root?(new_item.name)
      self.errors.add(:copy, I18n.t('repository_manager.errors.repo_item.item_exist'))
      raise RepositoryManager::ItemExistException.new("copy failed. The repo_folder '#{new_item.name}' already exist in root.")
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

    # Recursive method who copy all children.
    children.each do |c|
      c.copy!(source_folder: new_item, owner: options[:owner], sender: options[:sender])
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
    RepositoryManager::RepoItem.where('name = ? OR file = ?', name, name).where(id: child_ids).first ? true : false
  end

  # Returns true or false if the name exist in siblings
  def name_exist_in_siblings?(name)
    # We take all siblings without itself
    sibling_ids_without_itself = self.sibling_ids.delete(self.id)
    # We check if another item has the same name
    #RepositoryManager::RepoItem.where(name: name).where(id: sibling_ids_without_itself).first ? true : false
    RepositoryManager::RepoItem.where('name = ? OR file = ?', name, name).where(id: sibling_ids_without_itself).first ? true : false
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
