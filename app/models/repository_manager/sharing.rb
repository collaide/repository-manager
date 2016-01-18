class RepositoryManager::Sharing < ActiveRecord::Base
  self.table_name = :rm_sharings

  attr_accessible :can_read, :can_create, :can_update, :can_move, :can_delete, :can_share, :owner, :creator if RepositoryManager.protected_attributes?

  before_save :put_creator

  has_many :sharings_members, :class_name => 'RepositoryManager::SharingsMember', :dependent => :destroy
  belongs_to :owner, polymorphic: true
  belongs_to :creator, polymorphic: true
  belongs_to :repo_item, :class_name => 'RepositoryManager::RepoItem'

  validates_presence_of :repo_item

  #scope :recipient, lambda { |recipient|
  #  joins(:receipts).where('receipts.receiver_id' => recipient.id,'receipts.receiver_type' => recipient.class.base_class.to_s)
  #}
  #scope :members, lambda { |member|
  #  joins(:sharings_members).where('sharings_members.member_id' => member.id,'sharings_members.member_type' => member.class.base_class.to_s)
  #}

  # Return the permissions of the sharing for the member
  def get_permissions(member)
    # If the member is the owner, he can do what he want !
    if self.owner == member
      return true
    elsif i = self.sharings_members.where(member: member).first
      return {can_add: i.can_add, can_remove: i.can_remove}
    else
      return false
    end
  end

  # Add members to the sharing
  def add_members(members, sharing_permissions = RepositoryManager.default_sharing_permissions)
    if members.kind_of?(Array)
      # Add each member to this sharing
      members.each do |i|
        unless i.respond_to? :create_folder # Check if this object "has_repository"
          raise RepositoryManager::RepositoryManagerException.new("add members failed. The object passed into members should be a model who 'has_repository'")
        end
        sharing_member = RepositoryManager::SharingsMember.new(sharing_permissions)
        sharing_member.member = i
        # Add the sharings members in the sharing
        self.sharings_members << sharing_member
      end
    else
      unless members.respond_to? :create_folder # Check if this object "has_repository"
        raise RepositoryManager::RepositoryManagerException.new("add members failed. The object passed into members should be a model who 'has_repository'")
      end
      sharing_member = RepositoryManager::SharingsMember.new(sharing_permissions)
      sharing_member.member = members
      # Add the sharings members in the sharing
      self.sharings_members << sharing_member
    end
  end

  # Remove members to the sharing
  def remove_members(members)
    if members.kind_of?(Array)
      # Add each member to this sharing
      members.each do |member|
        self.sharings_members.where(member: member).first.destroy
      end
    else
      self.sharings_members.where(member: members).first.destroy
    end
  end

  private
  def put_creator
    self.creator = owner unless creator
  end

end
