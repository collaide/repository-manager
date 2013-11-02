class Repository < ActiveRecord::Base
  extend Enumerize

  enumerize :repository_type, in: [:folder, :file], default: :file

  acts_as_tree

  #Associate with the User Classe
  belongs_to :owner, :polymorphic => true
  has_many :shares

  mount_uploader :file, RepositoryUploader

  before_save :update_asset_attributes

  private

  def update_asset_attributes
    unless file.present?
      self.repository_type = :folder
    end
    if file.present? && file_changed?
      self.content_type = file.file.content_type
      self.file_size = file.file.size
    end
  end
end
