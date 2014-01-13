module RepositoryManager
  class RepositoryManagerException < RuntimeError
  end

  class AuthorisationException < RepositoryManagerException
  end

  class NestedSharingException < RepositoryManagerException
  end
end