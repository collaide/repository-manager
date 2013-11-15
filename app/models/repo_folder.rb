require 'zip'

class RepoFolder < RepoItem
  attr_accessible :name if RepositoryManager.protected_attributes?

  validates :name, presence: true

  # Add a repo_item in the folder.
  def add(repo_item)
    # We check if this name already exist
    if RepoItem.where(name: repo_item.name).where(id: child_ids).first
      #raise "add failed. The repo_item '#{repo_item.name}' already exist in the folder '#{name}'"
      false
    else
      repo_item.update_attribute :parent, self
    end
  end

  # Download this folder (zip it first)
  # If object = nil, it download all the folder
  # if object is set, it download only the folder that the object can_read.
  def download(object = nil)
    # Get all the children
    children = RepoItem.find(child_ids)

    # If something is in the array to add, we zip it
    if children.length > 0
      # We create the zip here
      Zip::File.open("#{name}.zip", Zip::File::CREATE) { |zf|
        add_repo_item_to_zip(children, zf, object)
      }
    else
      # Nothing to download here
      #raise "download failed. Folder #{name} is empty"
      false
    end

  end

  private

  def add_repo_item_to_zip(children, zf, object = nil, prefix = nil)
    children.each do |child|
      # If this is a file, we just add this file to the zip
      if child.type == 'RepoFile'
        # Add the file in the zip if the object is authorised to read it.
        zf.add("#{prefix}#{child.name}", child.file.current_path) if object == nil || object.can_read?(child)
      elsif child.type == 'RepoFolder'
        # If this folder has children, we do it again with it children
        if child.has_children?
          # We go in this new directory and add it repo_items
          add_repo_item_to_zip(RepoItem.find(child.child_ids), zf, object, "#{prefix}#{child.name}/")
        else
          # We just create the folder if it is empty
          zf.mkdir(child.name) if object == nil || object.can_read?(child)
        end
      end
    end
  end
end
