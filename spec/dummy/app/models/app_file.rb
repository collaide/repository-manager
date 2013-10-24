class AppFile < ActiveRecord::Base
  acts_as_nested_set

  #Associate with the User Classe
  belongs_to :owner, :polymorphic => true
  has_many :shares
end
