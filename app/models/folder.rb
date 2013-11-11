class Folder < Repository
  attr_accessible :name if RepositoryManager.protected_attributes?

  validates :name, presence: true

  # Add a repository in the folder.
  def add_repository(repository)
    repository.update_attribute :parent, self
  end

  # Download this folder (zip it first)
  # If object = nil, it download all the folder
  # if object is set, it download only the folder that the user can_read.
  def download(object = nil)
    # Get all the children
    children = Repository.find(child_ids)

    # The array that will contain all the children to zip
    children_to_add = []

    if children
      # If we have an object, we have to look at his permissions
      if object
        # For all repositories, we check if the object has the permission to read it
        children.each do |child|
          # If he can read it, add to the array
          children_to_add << child if object.can_read?(child)
        end
      else
        # Simply add all
        children_to_add = children
      end
    end

    # If something is in the array to add, we zip it
    if children_to_add.length > 1
      # We create the zip here
      Zip::File.open("#{name}.zip", Zip::File::CREATE) do |zipfile|
        children_to_add.each do |child|
          # Two arguments:
          # - The name of the file as it will appear in the archive
          # - The original file, including the path to find it
          zipfile.add(child.file.identifier, child.file.current_path)
        end
      end
    elsif children_to_add.length == 1
      children_to_add.first.file.path
    else
      # Nothing to download here
      false
    end
  end

end
