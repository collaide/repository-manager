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
    scope :on_root, -> { where ancestry: nil}
    scope :files, -> { where type: 'RepositoryManager::RepoFile' }
    scope :folders, -> { where type: 'RepositoryManager::RepoFolder' }
  else
    # Rails 3 does it this way
    scope :on_root, where(ancestry: nil)
    scope :files, where(type: 'RepositoryManager::RepoFile')
    scope :folders, where(type: 'RepositoryManager::RepoFolder')
  end

  # Copy itself into the target_folder
  # options
  #   :target_folder = the folder in witch you copy this item
  #   :owner = the owner of the item
  #   :sender = the sender of the item (if you specify owner and not sender.. The sender becomes the owner)
  def copy!(options = {})
    new_item = RepoItem.new
    new_item.type = self.type
    new_item.file = self.file
    new_item.content_type = self.content_type
    new_item.file_size = self.file_size
    new_item.name = self.name
    options[:owner] ? new_item.owner = options[:owner] : new_item.owner = self.owner
    if options[:sender]
      new_item.sender = options[:sender]
    elsif options[:owner]
      new_item.sender = options[:owner]
    else
      new_item.sender = self.sender
    end

    if options[:target_folder]
      options[:target_folder].add!(new_item)
    end

    new_item.save!
    new_item
  end

  def copy(options = {})
    begin
      copy!(options)
    rescue RepositoryManager::AuthorisationException, RepositoryManager::RepositoryManagerException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      false
    end
  end

  # Move itself into the target_folder or root
  # options
  #   :target_folder => move into this target_folder
  #   :owner = the owner of the item
  def move!(options = {})
    # If we are in target_folder, we check if it's ok
    if options[:target_folder]
      unless options[:target_folder].is_folder?
        raise RepositoryManager::RepositoryManagerException.new("move failed. target '#{target_folder.name}' can't be a file")
      end
      if options[:target_folder].name_exist_in_children?(self.name)
        raise RepositoryManager::RepositoryManagerException.new("move failed. The repo_item '#{name}' already exist ine the folder '#{target_folder.name}'")
      end
    else
      # We are in root, we check if name exist in root
      if options[:owner]
        if options[:owner].repo_item_name_exist_in_root?(self.name)
          raise RepositoryManager::RepositoryManagerException.new("move failed. The repo_item '#{name}' already exist ine the root")
        elsif self.owner.repo_item_name_exist_in_root?(self.name)
          raise RepositoryManager::RepositoryManagerException.new("move failed. The repo_item '#{name}' already exist ine the root")
        end
      end
    end
    # here, all is ok
    self.owner = options[:owner] if options[:owner]
    self.update_attribute :parent, options[:target_folder]
    self.save!
    self
  end

  def move(target_folder)
    begin
      move!(target_folder)
    rescue RepositoryManager::RepositoryManagerException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
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
