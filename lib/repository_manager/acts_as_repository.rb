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

        has_many :repositories, as: :owner #, dependent: :destroy

        #cattr_accessor :yaffle_text_field
        #self.yaffle_text_field = (options[:yaffle_text_field] || :last_squawk).to_s
        # your code will go here

        include RepositoryManager::ActsAsRepository::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      #Share the repository to the items, with the repo_permissions
      #share_permission contains :
      #can_add and can_remove specify if the users can add/remove people to the share
      def share(repository, items, repo_permissions = nil, share_permissions = nil)
        authorisations = get_authorisations(repository)

        #Here we look if the instance has the authorisation for making a share
        if can_share(nil, authorisations)

          repo_permissions = make_repo_permissions(repo_permissions, authorisations)

          share = Share.new(repo_permissions)
          share.owner = self

          repository.shares << share
          if items.kind_of?(Array)
            #add each item to this share
            items.each do |i|
              shareItem = SharesItem.new(share_permissions)
              shareItem.item = i
              #add the shares items in the share
              share.shares_items << shareItem
            end
          else
            shareItem = SharesItem.new(share_permissions)
            shareItem.item = items
            #add the shares items in the share
            share.shares_items << shareItem
          end


          repository.save
        else
          # No permission => No share
          false
        end
      end

      def createFolder(name, sourceFolder = nil)
        folder = Folder.new(name: name)
        folder.owner = self
        folder.save

        #If we want to create a folder in a folder, we have to check if we have the authorisation
        if sourceFolder
          #authorisations = get_authorisations(sourceFolder)
          sourceFolder.addRepository(folder)
        end

        return folder
      end

      #Return false if the entity has not the authorisation to share this rep
      #Return true if the entity can share this rep with all the authorisations
      #Return an Array if the entity can share but with restriction
      def get_authorisations(repository)
        # If the item is the owner, he can share !
        if repository.owner == self
          #You can do what ever you want :)
          return true
          #Find if a share of this rep exist for the self instance
        elsif s = self.shares.where(repository_id: repository.id).take
            #Ok, give an array with the permission of the actual share
            # (we can't share with more permission then we have)
            return {can_share: s.can_share, can_read: s.can_read, can_create: s.can_create, can_update: s.can_update, can_delete: s.can_delete}
        else
          #We look at the ancestor if there is a share
          ancestor_ids = repository.ancestor_ids
          #check the nearest share if it exist
          if s = self.shares.where(repository_id: ancestor_ids).last
            return {can_share: s.can_share, can_read: s.can_read, can_create: s.can_create, can_update: s.can_update, can_delete: s.can_delete}
          end
        end
        #else, false
        return false
      end

      #Return true if you can share the repo, false else
      #You can give the authorisations or the repository as params
      def can_share(repository, authorisations = nil)
        #If we pass no authorisations we have to get it
        if authorisations === nil
          authorisations = get_authorisations(repository)
        end
        return authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_share] == true)
      end

      private

      #Correct the repo_permissions with the authorisations
      def make_repo_permissions(wanted_permissions, authorisations)
        #If it is an array, we have restriction in the permissions
        if authorisations.kind_of?(Hash) && wanted_permissions
          #built the share with the accepted permissions
          #We remove the permission if we can't share it
          if wanted_permissions[:can_read] == true && authorisations[:can_read] == false
            wanted_permissions[:can_read] = false
          end
          if wanted_permissions[:can_create] == true && authorisations[:can_create] == false
            wanted_permissions[:can_create] = false
          end
          if wanted_permissions[:can_update] == true && authorisations[:can_update] == false
            wanted_permissions[:can_update] = false
          end
          if wanted_permissions[:can_delete] == true && authorisations[:can_delete] == false
            wanted_permissions[:can_delete] = false
          end
        end
        return wanted_permissions
      end

    end
  end
end

ActiveRecord::Base.send :include, RepositoryManager::ActsAsRepository