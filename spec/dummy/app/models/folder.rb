class Folder < Repository

  def addRepository(repository)
    repository.update_attribute :parent, self
  end
end
