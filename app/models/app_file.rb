class AppFile < ActiveRecord::Base
  acts_as_nested_set

  belongs_to :owner
  has_many :shares
end
