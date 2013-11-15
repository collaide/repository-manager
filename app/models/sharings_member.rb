class SharingsMember < ActiveRecord::Base
  attr_accessible :can_add, :can_remove if RepositoryManager.protected_attributes?

  belongs_to :member, polymorphic: true
  belongs_to :sharing
end