class SharesItem < ActiveRecord::Base
  belongs_to :shareable, polymorphic: true
  belongs_to :share

  #can_add
  #can_remove
  #t.references :shareable, polymorphic: true
end
