class RepoItem < ActiveRecord::Base
  attr_accessible :type if RepositoryManager.protected_attributes?


  has_ancestry

  # Associate with the User Class
  belongs_to :owner, :polymorphic => true
  has_many :sharings, :dependent => :destroy
  #has_many :members, through: :sharings

  if Rails::VERSION::MAJOR == 4
    scope :files, -> { where type: 'RepoFile' }
    scope :folders, -> { where type: 'RepoFolder' }
  else
    # Rails 3 does it this way
    scope :files, where(type: 'RepoFile')
    scope :folders, where(type: 'RepoFolder')
  end

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

  # Move itself into the target_folder
  def move(target_folder)
    if target_folder.type == 'RepoFolder'
      self.update_attribute :parent, target_folder
    else
      # target_folder can't be a file.
      false
    end
  end


end
