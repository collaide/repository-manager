class Folder < Repository

  #Add a repository in the folder.
  def addRepository(repository)
    repository.update_attribute :parent, self
  end
end
