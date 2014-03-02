class RepositoryManager::RepoItem < ActiveRecord::Base
  self.table_name = :rm_repo_items

  attr_accessible :type, :ancestry, :name, :owner, :sender if RepositoryManager.protected_attributes?

  before_save :put_sender

  has_ancestry cache_depth: true

  # Associate with the User Class
  belongs_to :owner, :polymorphic => true
  has_many :sharings, :class_name => 'RepositoryManager::Sharing', :dependent => :destroy
  #has_many :members, through: :sharings
  #belongs_to :user, class_name: RepositoryManager.user_model if RepositoryManager.user_model
  belongs_to :sender, polymorphic: true

  validates_presence_of :owner

  if Rails::VERSION::MAJOR == 4
    scope :on_root, -> { where ancestry: nil}
    scope :files, -> { where type: 'RepositoryManager::RepoFile' }
    scope :folders, -> { where type: 'RepositoryManager::RepoFolder' }
  else
    # Rails 3 does it this way
    scope :on_root, where(ancestry: nil)
    scope :files, where(type: 'RepositoryManager::RepoFile')
    scope :folders, where(type: 'RepositoryManager::RepoFolder')
  end

  # Move itself into the target or root
  # options
  #   :source_folder = the folder in witch you copy this item
  #   :owner = the owner of the item
  # If :source_folder = nil, move to the root (of same owner)
  def move!(options = {})
    # If we are in source_folder, we check if it's ok
    if options[:source_folder]
      unless options[:source_folder].is_folder?
        raise RepositoryManager::RepositoryManagerException.new("move failed. target '#{options[:source_folder].name}' can't be a file")
      end
      if options[:source_folder].name_exist_in_children?(self.name)
        raise RepositoryManager::RepositoryManagerException.new("move failed. The repo_item '#{name}' already exist ine the folder '#{options[:source_folder].name}'")
      end
    # We are in root, we check if name exist in root
    # We stay in the same owner
    elsif self.owner.repo_item_name_exist_in_root?(self.name)
      raise RepositoryManager::RepositoryManagerException.new("move failed. The repo_item '#{name}' already exist ine the root")
    end
    # here, all is ok
    # We change the owner if another one is specify
    if options[:owner]
      self.owner = options[:owner]
    elsif options[:source_folder]
      self.owner = options[:source_folder].owner
    end
    # we update the tree with the new parent
    self.update_attribute :parent, options[:source_folder]
    self.save!
    self
  end

  def move(options = {})
    begin
      move!(options)
    rescue RepositoryManager::RepositoryManagerException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      false
    end
  end

  # Returns true if it exist a sharing in the ancestors of descendant_ids of the repo_item (without itself)
  def can_be_shared_without_nesting?
    # An array with the ids of all ancestors and descendants
    ancestor_and_descendant_ids = []
    ancestor_and_descendant_ids << self.descendant_ids if self.is_folder? && !self.descendant_ids.empty?
    ancestor_and_descendant_ids << self.ancestor_ids if !self.ancestor_ids.empty?

    # If it exist a sharing, it returns true
    if RepositoryManager::Sharing.where(repo_item_id: ancestor_and_descendant_ids).count > 0
      false
    else
      true
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
