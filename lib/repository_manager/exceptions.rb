module RepositoryManager
  class RepositoryManagerException < RuntimeError
  end

  class PermissionException < RepositoryManagerException
  end

  class NestedSharingException < RepositoryManagerException
  end
end