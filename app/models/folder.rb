class Folder < Repository
  attr_accessible :name if RepositoryManager.protected_attributes?

  validates :name, presence: true

  #Add a repository in the folder.
  def addRepository(repository)
    repository.update_attribute :parent, self
  end

end
