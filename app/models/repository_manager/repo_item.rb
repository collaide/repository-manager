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
  #   :destroy_if_fail = false // the repo_item if it can't move it.
  #   :do_not_save = false // Save the repo_item after changing his param
  #   :source_folder = the folder in witch you copy this item
  #   :owner = the owner of the item
  #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')
  # If :source_folder = nil, move to the root (of same owner)
  def move!(options = {})
    returned_item = self
    !!options[:overwrite] == options[:overwrite] ? overwrite = options[:overwrite] : overwrite = RepositoryManager.auto_overwrite_item

    # Do nothing if moving to current folder
    return self if options[:source_folder] == self.parent && (options[:owner] || self.owner) == self.owner

    # If we are in source_folder, we check if it's a folder
    if options[:source_folder] && !(options[:source_folder].is_folder?)
      self.destroy if options[:destroy_if_fail]
      raise RepositoryManager::RepositoryManagerException.new("Move failed. Target '#{options[:source_folder].name}' can't be a file")
    end

    # Check if moving to another folder or root
    if options[:source_folder].present?
      child_with_same_name = options[:source_folder].get_child_by_name(self.name, self.type)
    else
      child_with_same_name = (options[:owner] || self.owner).get_item_in_root_by_name(self.name, self.type)
    end

    # If the name exists and we don't want to overwrite, we raise an error
    if child_with_same_name and !overwrite
      self.errors.add(:move, I18n.t('repository_manager.errors.repo_item.item_exist'))
      # we delete the repo if asked
      self.destroy if options[:destroy_if_fail]
      raise RepositoryManager::ItemExistException.new("Move failed. A repo_#{self.is_file? ? 'file' : 'folder'} named '#{name}' already exists in #{options[:source_folder].try(:name) || 'root'} folder")
    elsif child_with_same_name and overwrite
      # If a child with the same name exists and we want to overwrite,
      # we destroy or update it
      if child_with_same_name.is_file?
        child_with_same_name.file = self.file
        child_with_same_name.sender = self.sender
        child_with_same_name.metadata = self.metadata
        #child_with_same_name.owner = self.owner
        returned_item = child_with_same_name
        self.destroy
      else
        destroy_child_with_same_name = true
      end
    end

    # Here, all is ok
    # Change the owner if another one is specified
    if options[:owner]
      returned_item.owner = options[:owner]
    elsif options[:source_folder]
      returned_item.owner = options[:source_folder].owner
    end

    # Update the tree with the new parent
    returned_item.parent = options[:source_folder]
    returned_item.save! unless options[:do_not_save]
    child_with_same_name.destroy! if destroy_child_with_same_name
    returned_item
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

  # Returns true if there is a sharing in the ancestors of descendant_ids of the repo_item (without itself)
  def can_be_shared_without_nesting?
    # An array with the ids of all ancestors and descendants
    ancestor_and_descendant_ids = []
    ancestor_and_descendant_ids << self.descendant_ids if self.is_folder? && !self.descendant_ids.empty?
    ancestor_and_descendant_ids << self.ancestor_ids if !self.ancestor_ids.empty?

    # If it exist a sharing, it returns true
    if RepositoryManager::Sharing.where(repo_item_id: ancestor_and_descendant_ids.flatten).count > 0
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
