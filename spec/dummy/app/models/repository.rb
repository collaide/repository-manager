class Repository < ActiveRecord::Base
  has_ancestry

  #Associate with the User Classe
  belongs_to :owner, :polymorphic => true
  has_many :shares

  scope :files, -> { where type: 'AppFile' }
  scope :folders, -> { where type: 'Folder' }

  def copy(target_folder)
    #new_file = self.dup
    #new_file.folder = target_folder
    #new_file.save!
    #
    #path = "#{Rails.root}/uploads/#{Rails.env}/#{new_file.id}/original"
    #FileUtils.mkdir_p path
    #FileUtils.cp_r self.attachment.path, "#{path}/#{new_file.id}"
    #
    #new_file
  end

  #Move the repository into the target_folder
  #TODO à tester
  def move(target_folder)
    if target_folder.type == 'Folder'
      self.update_attribute :parent, target_folder
    end
  end


end
