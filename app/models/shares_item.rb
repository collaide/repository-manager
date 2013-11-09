class SharesItem < ActiveRecord::Base
  attr_accessible :can_add, :can_remove if RepositoryManager.protected_attributes?

  belongs_to :item, polymorphic: true
  belongs_to :share

  #can_add
  #can_remove
  #t.references :shareable, polymorphic: true
end
