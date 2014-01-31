require 'zip'

class RepoFolder < RepoItem
  attr_accessible :name if RepositoryManager.protected_attributes?

  validates :name, presence: true

  before_validation :default_name

  # Add a repo_item in the folder.
  def add!(repo_item)
    # We check if this name already exist
    #if repo_item.children.exists?(:name => repo_item.name)
    if RepoItem.where(name: repo_item.name).where(id: child_ids).first
      raise RepositoryManager::RepositoryManagerException.new("add failed. The repo_item '#{repo_item.name}' already exist in the folder '#{name}'")
    else
      repo_item.update_attribute :parent, self
    end
  end

  def add(repo_item)
    begin
      add!(repo_item)
    rescue RepositoryManager::RepositoryManagerException
      false
    end
  end

  # Rename the item
  def rename!(new_name)
    # We take all siblings without itself
    sibling_ids_without_itself = self.sibling_ids.delete(self.id)
    # We check if another item has the same name
    if RepoItem.where(name: self.name).where(id: sibling_ids_without_itself).first
      raise RepositoryManager::RepositoryManagerException.new("rename failed. The repo_item '#{new_name}' already exist.'")
    else
      self.name = new_name
    end
  end

  # Rename the item
  def rename(new_name)
    begin
      rename!(new_name)
    rescue RepositoryManager::RepositoryManagerException
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
    children = RepoItem.find(child_ids)

    # If something is in the array to add, we zip it
    if children.length > 0

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
      return full_path
    else
      # Nothing to download here
      raise RepositoryManager::RepositoryManagerException.new("download failed. Folder #{name} is empty")
    end
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

  private

  # Returns the default path of the zip file
  # object is the object that want to download this file
  def get_default_download_path(object = nil)
    object ? add_to_path = object.get_default_download_path(''): add_to_path = ''
    "download/#{add_to_path}#{self.class.to_s.underscore}/#{self.id}/"
  end

  def add_repo_item_to_zip(children, zf, object = nil, prefix = nil)
    children.each do |child|
      # If this is a file, we just add this file to the zip
      if child.type == 'RepoFile'
        # Add the file in the zip if the object is authorised to read it.
        zf.add("#{prefix}#{child.name}", child.file.current_path) if object == nil || !RepositoryManager.accept_nested_sharing || object.can_read?(child)
      elsif child.type == 'RepoFolder'
        # If this folder has children, we do it again with it children
        if child.has_children?
          # We go in this new directory and add it repo_items
          add_repo_item_to_zip(RepoItem.find(child.child_ids), zf, object, "#{prefix}#{child.name}/")
        else
          # We just create the folder if it is empty
          zf.mkdir(child.name) if object == nil || !RepositoryManager.accept_nested_sharing || object.can_read?(child)
        end
      end
    end
  end

  private
  def default_name
    if name.empty?
      i = ''
      self.name = "#{I18n.t 'repository_manager.models.repo_folder.name'}#{i}"
      # We take all siblings without itself
      sibling_ids_without_itself = self.sibling_ids.delete(self.id)
      # We check if another item has the same name
      until RepoItem.where(name: self.name).where(id: sibling_ids_without_itself).first
        if i == ''
          i = 0
        end
        i = i + 1
      end
      self.name = "#{I18n.t 'repository_manager.models.repo_folder.name'}#{i}"
    end
  end
end
