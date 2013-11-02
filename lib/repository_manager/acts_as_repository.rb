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
        if authorisation = can_share(repository)
          #If it is an array, we have restriction in the permissions
          if authorisation.kind_of?(Hash) && repo_permissions.kind_of?(Hash)
            #built the share with the accepted permissions
            #We remove the permission if we can't share it
            if repo_permissions[:can_read] == true && authorisation[:can_read] == false
              repo_permissions[:can_read] = false
            end
            if repo_permissions[:can_create] == true && authorisation[:can_create] == false
              repo_permissions[:can_create] = false
            end
            if repo_permissions[:can_update] == true && authorisation[:can_update] == false
              repo_permissions[:can_update] = false
            end
            if repo_permissions[:can_delete] == true && authorisation[:can_delete] == false
              repo_permissions[:can_delete] = false
            end
          end

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
          # No permission => No share
          false
        end
      end

      private

      #Return false if the entity has not the authorisation to share this rep
      #Return true if the entity can share this rep with all the authorisations
      #Return an Array if the entity can share but with restriction
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
                # (we can't share with more permission then we have)
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