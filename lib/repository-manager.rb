require 'repository_manager/has_repository'

module RepositoryManager

  class << self
    def setup
      yield self
    end

    def protected_attributes?
      Rails.version < '4' || defined?(ProtectedAttributes)
    end
  end

end

require 'repository_manager/engine'