module RepositoryManager
  module HasRepository
    extend ActiveSupport::Concern

    module ClassMethods
      def has_repository(options = {})

        has_many :sharings, through: :sharings_members
        has_many :sharings_members, as: :member, dependent: :destroy
        has_many :sharings_owners, as: :owner, class_name: 'Sharing'

        # The own repo_items
        has_many :repo_items, as: :owner #, dependent: :destroy
        # The sharing repo_items
        has_many :shared_repo_items, through: :sharings, source: :repo_item, class_name: 'RepoItem'

        #scope :all_repo_items, -> { self.repo_items.shared_repo_items }

        #All repo_items (own and sharings)
        #has_many :all_repo_items

        include RepositoryManager::HasRepository::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods

      # Sharing the repo_item with the members, with the options
      # options[:repo_item_permissions] contains :
      #   <tt>:can_read</tt> - Member can download the repo_item
      #   <tt>:can_create</tt> - Member can create a new repo_item on it
      #   <tt>:can_edit</tt> - Member can edit the repo_item
      #   <tt>:can_delete</tt> - Member can delete the repo_item
      #   <tt>:can_share</tt> - Member can share the repo_item
      # options[:sharing_permissions] contains :
      #   <tt>:can_add</tt> - Specify if the member can add objects to the sharing
      #   <tt>:can_remove</tt> - Specify if the member can remove object to the sharing
      def share(repo_item, members, options = nil)
        authorisations = get_authorisations(repo_item)

        # Here we look if the instance has the authorisation for making a sharing
        if can_share?(nil, authorisations)

          # We put the default options
          repo_item_permissions = RepositoryManager.default_repo_item_permissions
          sharing_permissions = RepositoryManager.default_sharing_permissions

          # If there is options, we have to take it
          if options
            repo_item_permissions = options[:repo_item_permissions] if options[:repo_item_permissions]
            sharing_permissions = options[:sharing_permissions] if options[:sharing_permissions]
          end

          repo_item_permissions = make_repo_item_permissions(repo_item_permissions, authorisations)

          sharing = Sharing.new(repo_item_permissions)
          sharing.owner = self

          sharing.add_members(members, sharing_permissions)

          repo_item.sharings << sharing
          repo_item.save
          sharing
        else
          # No permission => No sharing
          #raise "sharing failed. You don't have the permission to share the repo_item '#{repo_item.name}'"
          false
        end
      end

      # Create a folder with the name (name) in the directory (source_folder)
      # Returns the object of the folder created if it is ok
      # Returns false if the folder is not created (no authorisation)
      def create_folder(name = 'New folder', source_folder = nil)
        # If he want to create a folder in a directory, we have to check if he have the authorisation
        if can_create?(source_folder)

          folder = RepoFolder.new(name: name)
          folder.owner = self
          folder.save

          # We have to look if it is ok to add the folder here
          if source_folder == nil || source_folder.add(folder)
            folder
          else
            # The add didn't works, we delete the folder
            folder.destroy
            #raise "create_folder failed. The folder '#{name}' already exist in folder '#{source_folder.name}'"
            false
          end
        else
          #raise "create_folder failed. You don't have the permission to create a folder in '#{source_folder.name}'"
          return false
        end
      end

      # Delete the repo_item
      def delete_repo_item(repo_item)
        if can_delete?(repo_item)
          repo_item.destroy
        else
          #raise "delete_repo_item failed. You don't have the permission to delete the repo_item '#{repo_item.name}'"
          return false
        end
      end

      # Create the file (file) in the directory (source_folder)
      # Param file can be a File, or a instance of RepoFile
      # Return the object of the file created if it is ok
      # Return false if the file is not created (no authorisation)
      def create_file(file, source_folder = nil)
        # If he want to create a file in a directory, we have to check if he have the authorisation
        if can_create?(source_folder)
          if file.class.name == 'File'
            repo_file = RepoFile.new
            repo_file.file = file
            repo_file.owner = self
            repo_file.save
          elsif file.class.name == 'RepoFile'
            repo_file = file
            repo_file.owner = self
            repo_file.save
          end

          # We have to look if it is ok to add the file here
          if source_folder == nil || source_folder.add(file)
            return repo_file
          else
            # The add didn't works, we delete the file
            file.destroy
            #raise "create_file failed. The file '#{name}' already exist in folder '#{source_folder.name}'"
            return false
          end
        else
          #raise "create_file failed. You don't have the permission to create a file in the folder '#{source_folder.name}'"
          return false
        end
      end

      # Gets the repo authorisations
      # Return false if the entity has not the authorisation to share this rep
      # Return true if the entity can share this rep with all the authorisations
      # Return an Array if the entity can share but with restriction
      # Return true if the repo_item is nil (he as all authorisations on his own rep)
      def get_authorisations(repo_item = nil)
        # If repo_item is nil, he can do what he want
        return true if repo_item == nil

        # If the member is the owner, he can do what he want !
        if repo_item.owner == self
          # You can do what ever you want :)
          return true
          # Find if a sharing of this rep exist for the self instance
        elsif s = self.sharings.where(repo_item_id: repo_item.id).first
          # Ok, give an array with the permission of the actual sharing
          # (we can't share with more permission then we have)
          return {can_share: s.can_share, can_read: s.can_read, can_create: s.can_create, can_update: s.can_update, can_delete: s.can_delete}
        else
          # We look at the ancestor if there is a sharing
          ancestor_ids = repo_item.ancestor_ids
          # Check the nearest sharing if it exist
          if s = self.sharings.where(repo_item_id: ancestor_ids).last
            return {can_share: s.can_share, can_read: s.can_read, can_create: s.can_create, can_update: s.can_update, can_delete: s.can_delete}
          end
        end
        # Else, false
        return false
      end

      # Download a repo_item if the object can_read it
      # If it is a file, he download the file
      # If it is a folder, we check witch repo_item is in it, and witch he can_read
      # We zip all the content that the object has access.
      # options
      #   :path => 'path/to/zip'
      def download(repo_item, options = nil)
        if can_download?(repo_item)
          if options
            path = options[:path] if options[:path]
          end
          repo_item.download({object: self, path: path})
        else
          #raise "download failed. You don't have the permission to download the repo_item '#{repo_item.name}'"
          false
        end
      end

      #Return the authorisations of the sharing (can_add, can_remove)
      def get_sharing_authorisations(sharing)
        sharing.get_authorisations(self)
      end

      # Return true if you can share the repo, else false
      # You can give the authorisations or the repo_item as params
      def can_share?(repo_item, authorisations = nil)
        can_do?('share', repo_item, authorisations)
      end

      # Return true if you can read the repo, else false
      def can_read?(repo_item, authorisations = nil)
        can_do?('read', repo_item, authorisations)
      end

      # Return true if you can download the repo, else false
      # Read = Download for the moment
      def can_download?(repo_item, authorisations = nil)
        can_do?('read', repo_item, authorisations)
      end

      # Return true if you can create in the repo, false else
      def can_create?(repo_item, authorisations = nil)
        can_do?('create', repo_item, authorisations)
      end

      # Return true if you can edit the repo, false else
      def can_update?(repo_item, authorisations = nil)
        can_do?('update', repo_item, authorisations)
      end

      # Return true if you can delete the repo, false else
      def can_delete?(repo_item, authorisations = nil)
        can_do?('delete', repo_item, authorisations)
      end

      # Return true if you can add a member in this sharing, false else
      def can_add_to?(sharing)
        can_do_to?('add', sharing)
      end

      # Return true if you can remove a member in this sharing, false else
      def can_remove_from?(sharing)
        can_do_to?('remove', sharing)
      end

      # You can here add new members in the sharing
      # Param member could be an object or an array of object
      def add_members_to(sharing, members, options = RepositoryManager.default_sharing_permissions)
        authorisations = get_sharing_authorisations(sharing)
        if can_add_to?(sharing)
          sharing_permissions = make_sharing_permissions(options, authorisations)
          sharing.add_members(members, sharing_permissions)
        else
          #raise "add members failed. You don't have the permission to add a member in this sharing"
          return false
        end
      end

      # You can here add new members in the sharing
      # Param member could be an object or an array of object
      def remove_members_from(sharing, members)
        if can_remove_from?(sharing)
          sharing.remove_members(members)
        else
          #raise "remove members failed. You don't have the permission to remove a member on this sharing"
          return false
        end
      end

      private

      # Return if you can do or not this action in the sharing
      def can_do_to?(what, sharing, authorisations = nil)
        if authorisations == nil
          authorisations = sharing.get_authorisations(self)
        end
        case what
          when 'add'
            authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_add] == true)
          when 'remove'
            authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_remove] == true)
        end
      end

      # Return if you can do or not this action (what)
      def can_do?(what, repo_item, authorisations = nil)
        #If we pass no authorisations we have to get it
        if authorisations === nil
          authorisations = get_authorisations(repo_item)
        end

        case what
          when 'read'
            authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_read] == true)
          when 'delete'
            authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_delete] == true)
          when 'update'
            authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_update] == true)
          when 'share'
            authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_share] == true)
          when 'create'
            authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_create] == true)
          else
            false
        end

      end

      # Correct the repo_item_permissions with the authorisations
      def make_repo_item_permissions(wanted_permissions, authorisations)
        # If it is an array, we have restriction in the permissions
        if authorisations.kind_of?(Hash) && wanted_permissions
          # Built the sharing with the accepted permissions
          # We remove the permission if we can't sharing it
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
          if wanted_permissions[:can_share] == true && authorisations[:can_share] == false
            wanted_permissions[:can_share] = false
          end
        end
        return wanted_permissions
      end

      # Correct the sharing_permissions with the authorisations
      def make_sharing_permissions(wanted_permissions, authorisations)
        # If it is an array, we have restriction in the permissions
        if authorisations.kind_of?(Hash) && wanted_permissions
          # Built the sharing with the accepted permissions
          # We remove the permission if we can't share it
          if wanted_permissions[:can_add] == true && authorisations[:can_add] == false
            wanted_permissions[:can_add] = false
          end
          if wanted_permissions[:can_remove] == true && authorisations[:can_remove] == false
            wanted_permissions[:can_remove] = false
          end
        end
        return wanted_permissions
      end

    end
  end
end

ActiveRecord::Base.send :include, RepositoryManager::HasRepository