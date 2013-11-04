class Repository < ActiveRecord::Base
  has_ancestry

  #Associate with the User Classe
  belongs_to :owner, :polymorphic => true
  has_many :shares

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

  def move(target_folder)
    #self.folder = target_folder
    #save!
  end


end
