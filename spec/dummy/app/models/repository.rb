class Repository < ActiveRecord::Base
  acts_as_tree

  #Associate with the User Classe
  belongs_to :owner, :polymorphic => true
  has_many :shares

  mount_uploader :repository, RepositoryUploader
end
