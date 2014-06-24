class RepositoryManager::RepoItem < ActiveRecord::Base
  self.table_name = :rm_repo_items

  attr_accessible :type, :ancestry, :name, :owner, :sender if RepositoryManager.protected_attributes?

  before_save :put_sender

  if RepositoryManager.has_paper_trail
    has_paper_trail
  end

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
  #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')
  # If :source_folder = nil, move to the root (of same owner)
  def move!(options = {})
    !!options[:overwrite] == options[:overwrite] ? overwrite = options[:overwrite] : overwrite = RepositoryManager.auto_overwrite_item

    # If we are in source_folder, we check if it's a folder
    if options[:source_folder]
      unless options[:source_folder].is_folder?
        raise RepositoryManager::RepositoryManagerException.new("move failed. target '#{options[:source_folder].name}' can't be a file")
      end

      children_with_same_name = options[:source_folder].get_children_by_name(self.name)
      # If the name exist and we don't want to overwrite, we raise an error
      if children_with_same_name and !overwrite
        self.errors.add(:move, I18n.t('repository_manager.errors.repo_item.item_exist'))
        raise RepositoryManager::ItemExistException.new("move failed. The repo_item '#{name}' already exist ine the folder '#{options[:source_folder].name}'")
      elsif children_with_same_name and overwrite
        # If a children with the same name exist and we want to overwrite, we have to destroy it
        children_with_same_name.destroy!
      end
    # We are in root, we check if name exist in root
    # We stay in the same owner
    else
      # We check if a children with same name exist
      children_with_same_name = self.owner.get_item_in_root_by_name(self.name)

      # If it exist and we don t want to overwrite, we raise an error
      if children_with_same_name and !overwrite
        self.errors.add(:move, I18n.t('repository_manager.errors.repo_item.item_exist'))
        raise RepositoryManager::ItemExistException.new("move failed. The repo_item '#{name}' already exist ine the root")
      # else we destroy it
      elsif children_with_same_name and overwrite
        children_with_same_name.destroy!
      end
    end

    # here, all is ok
    # We change the owner if another one is specify
    if options[:owner]
      self.owner = options[:owner]
    elsif options[:source_folder]
      self.owner = options[:source_folder].owner
    end
    # we update the tree with the new parent
    self.parent = options[:source_folder]
    self.save!
    self
  end

  def move(options = {})
    begin
      move!(options)
    rescue RepositoryManager::RepositoryManagerException, RepositoryManager::ItemExistException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      false
    end
  end

  # Rename the item
  def rename!(new_name)
    if name_exist_in_siblings?(new_name)
      self.errors.add(:copy, I18n.t('repository_manager.errors.repo_item.item_exist'))
      raise RepositoryManager::ItemExistException.new("rename failed. The repo_item '#{new_name}' already exist.'")
    else
      self.name = new_name
      save!
    end
  end

  # Rename the item
  def rename(new_name)
    begin
      rename!(new_name)
    rescue RepositoryManager::ItemExistException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
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

  # Returns true or false if the name exist in siblings
  def name_exist_in_siblings?(name)
    # We take all siblings without itself
    sibling_ids_without_itself = self.sibling_ids.delete(self.id)
    # We check if another item has the same name
    #RepositoryManager::RepoItem.where(name: name).where(id: sibling_ids_without_itself).first ? true : false
    RepositoryManager::RepoItem.where('name = ?', name).where(id: sibling_ids_without_itself).first ? true : false
  end

  private
  def put_sender
    self.sender = owner unless sender
  end
end
