class Sharing < ActiveRecord::Base
  attr_accessible :can_read, :can_create, :can_update, :can_delete, :can_share if RepositoryManager.protected_attributes?

  has_many :sharings_members, :dependent => :destroy
  belongs_to :owner, :polymorphic => true
  belongs_to :repo_item
  belongs_to :user, class_name: RepositoryManager.user_model if RepositoryManager.user_model


  #scope :recipient, lambda { |recipient|
  #  joins(:receipts).where('receipts.receiver_id' => recipient.id,'receipts.receiver_type' => recipient.class.base_class.to_s)
  #}
  scope :members, lambda { |member|
    joins(:sharings_members).where('sharings_members.member_id' => member.id,'sharings_members.member_type' => member.class.base_class.to_s)
  }

  # Return the authorisations of the sharing for the member
  def get_authorisations(member)
    # If the member is the owner, he can do what he want !
    if self.owner == member
      return true
    elsif i = self.sharings_members.where(member_id: member.id, member_type: member.class.base_class.to_s).first
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
        sharing_member = SharingsMember.new(sharing_permissions)
        sharing_member.member = i
        # Add the sharings members in the sharing
        self.sharings_members << sharing_member
      end
    else
      sharing_member = SharingsMember.new(sharing_permissions)
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
        self.sharings_members.where(:member_id => member.id, :member_type => member.class.base_class.to_s).first.destroy
      end
    else
      self.sharings_members.where(:member_id => members.id, :member_type => members.class.base_class.to_s).first.destroy
    end
  end

end
