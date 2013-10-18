class Share < ActiveRecord::Base
  has_many :shares_items, as: :shareable
  belongs_to :owner
  belongs_to :app_file
  has_one :permission

end
