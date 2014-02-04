class RepositoryManager::SharingsMember < ActiveRecord::Base
  self.table_name = :rm_sharings_members

  attr_accessible :can_add, :can_remove if RepositoryManager.protected_attributes?

  belongs_to :member, polymorphic: true
  belongs_to :sharing, :class_name => 'RepositoryManager::Sharing'
end