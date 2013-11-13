require 'zip'

class Folder < Repository
  attr_accessible :name if RepositoryManager.protected_attributes?

  validates :name, presence: true

  # Add a repository in the folder.
  def add(repository)
    # TODO Verify if the file already exist on this folder
    repository.update_attribute :parent, self
  end

  # Download this folder (zip it first)
  # If object = nil, it download all the folder
  # if object is set, it download only the folder that the user can_read.
  def download(object = nil)
    # Get all the children
    children = Repository.find(child_ids)
    pp "Descendant: #{child_ids}"

    # If something is in the array to add, we zip it
    if children.length > 0
      # We create the zip here
      Zip::File.open("#{name}.zip", Zip::File::CREATE) { |zf|
        add_repository_to_zip(children, zf, object)
      }
    else
      # Nothing to download here
      false
    end

  end

  private

  def add_repository_to_zip(children, zf, object = nil, prefix = nil)
    children.each do |child|
      # If this is a file, we just add this file to the zip
      if child.type == 'AppFile'
        # Add the file in the zip if the object is authorised to read it.
        zf.add("#{prefix}#{child.name}", child.file.current_path) if object == nil || object.can_read?(child)
      elsif child.type == 'Folder'
        # If this folder has children, we do it again with it children
        if child.has_children?
          # We go in this new dir
          #zf.dir.chdir(child.name)
          add_repository_to_zip(Repository.find(child.child_ids), zf, object, "#{prefix}#{child.name}/")
        else
          # We just create the folder if it is empty
          zf.mkdir(child.name) if object == nil || object.can_read?(child)
        end
      end
    end
  end


end
