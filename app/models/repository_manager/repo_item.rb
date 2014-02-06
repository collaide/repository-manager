class RepositoryManager::RepoItem < ActiveRecord::Base
  self.table_name = :rm_repo_items

  attr_accessible :type, :ancestry, :name, :owner, :sender if RepositoryManager.protected_attributes?

  before_save :put_sender

  has_ancestry

  # Associate with the User Class
  belongs_to :owner, :polymorphic => true
  has_many :sharings, :class_name => 'RepositoryManager::Sharing', :dependent => :destroy
  #has_many :members, through: :sharings
  #belongs_to :user, class_name: RepositoryManager.user_model if RepositoryManager.user_model
  belongs_to :sender, polymorphic: true

  validates_presence_of :owner

  if Rails::VERSION::MAJOR == 4
    scope :on_root, -> { where ancestry: nil }
    scope :files, -> { where type: 'RepositoryManager::RepoFile' }
    scope :folders, -> { where type: 'RepositoryManager::RepoFolder' }
  else
    # Rails 3 does it this way
    scope :on_root, where(where ancestry: nil)
    scope :files, where(type: 'RepositoryManager::RepoFile')
    scope :folders, where(type: 'RepositoryManager::RepoFolder')
  end

  # Copy itself into the target_folder
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
  def move!(target_folder)
    unless target_folder.is_folder?
      raise RepositoryManager::RepositoryManagerException.new("move failed. target '#{target_folder.name}' can't be a file")
    end
    if target_folder.name_exist_in_children?(self.name)
      raise RepositoryManager::RepositoryManagerException.new("move failed. The repo_item '#{name}' already exist ine the folder '#{target_folder.name}'")
    end
    self.update_attribute :parent, target_folder
  end

  def move(target_folder)
    begin
      move!(target_folder)
    rescue RepositoryManager::RepositoryManagerException
      false
    end
  end

  # Returns true if it exist a sharing in the ancestors of descendant_ids of the repo_item (without itself)
  def has_nested_sharing?
    # An array with the ids of all ancestors and descendants
    ancestor_and_descendant_ids = []
    ancestor_and_descendant_ids << self.descendant_ids if self.is_folder? && !self.descendant_ids.empty?
    ancestor_and_descendant_ids << self.ancestor_ids if !self.ancestor_ids.empty?

    # If it exist a sharing, it returns true
    if RepositoryManager::Sharing.where(repo_item_id: ancestor_and_descendant_ids).count > 0
      true
    else
      false
    end
  end

  # Returns true if it is a folder
  def is_folder?
    self.type == 'RepositoryManager::RepoFolder'
  end

  # Returns true if it is a file
  def is_file?
    self.type == 'RepositoryManager::RepoFile'
  end

  private
  def put_sender
    self.sender = owner unless sender
  end
end
