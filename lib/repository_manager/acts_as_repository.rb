module RepositoryManager
  module ActsAsRepository
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_repository(options = {})

        has_many :shares, :through => :shares_items, dependent: :destroy
        has_many :shares_items, as: :item, dependent: :destroy
        has_many :shares_owners, as: :owner, :class_name => 'Share'

        has_many :repositories, as: :owner#, dependent: :destroy

        #cattr_accessor :yaffle_text_field
        #self.yaffle_text_field = (options[:yaffle_text_field] || :last_squawk).to_s
        # your code will go here

        include RepositoryManager::ActsAsRepository::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def test(string)
        "test: #{string}"
        #write_attribute(self.class.yaffle_text_field, string.to_squawk)
      end

      #Share the repository to the items, with the repo_permissions
      #share_permission contains :
        #can_add and can_remove specifie if the users can add/remove people to the share
      def share(repository, items, repo_permissions = nil, share_permissions = nil)
        #TODO verifie if the item can share with this rep_permissions
        if authorisation = can_share(repository)

          #built the share
          share = Share.new(repo_permissions)
          share.owner = self

          repository.shares << share

          #add each item to this share
          items.each do |i|
            shareItem = SharesItem.new(share_permissions)
            shareItem.item = i
            #add the shares items in the share
            share.shares_items << shareItem
          end

          repository.save
        else
          # No share
          false
        end
      end

      private

      #false if the entity has not the authorisation to share this rep
      def can_share(rep)
        # If the item is the owner, he can share !
        if rep.owner == self
          #You can do what ever you want :)
          return true
        else
          #look in the shares
          self.shares.each do |s|
            if s.repository == rep
              #He go the rep, but can he share it ?
              if s.can_share
                #Ok, give an array with the permission of the actual share
                # (he can't share with more permission then here)
                return {can_read: s.can_read, can_create: s.can_create, can_update: s.can_update, can_delete: s.can_delete}
              end
            end
          end
          #else, false
          return false
        end
      end
    end

  end
end

ActiveRecord::Base.send :include, RepositoryManager::ActsAsRepository