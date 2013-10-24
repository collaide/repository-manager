class User < ActiveRecord::Base

  has_and_belongs_to_many :groups

  #belongs_to :owner, polymorphic: true

  acts_as_repository

end
