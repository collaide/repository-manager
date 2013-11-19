module RepositoryManager
  class RepositoryManagerException < RuntimeError
  end

  class AuthorisationException < RepositoryManagerException
  end
end