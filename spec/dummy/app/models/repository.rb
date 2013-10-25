class Repository < ActiveRecord::Base
  acts_as_tree

  #Associate with the User Classe
  belongs_to :owner, :polymorphic => true
  has_many :shares

  mount_uploader :repository, RepositoryUploader

  before_save :update_asset_attributes

  private

  def update_asset_attributes
    if repository.present? && repository_changed?
      self.content_type = repository.file.content_type
      self.file_size = repository.file.size
    end
  end
end
