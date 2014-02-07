module RepositoryManager
  module HasRepository
    extend ActiveSupport::Concern

    module ClassMethods
      def has_repository(options = {})

        has_many :sharings, through: :sharings_members, class_name: 'RepositoryManager::Sharing'
        has_many :sharings_members, class_name: 'RepositoryManager::SharingsMember', as: :member, dependent: :destroy
        has_many :sharings_owners, as: :owner, class_name: 'RepositoryManager::Sharing'

        # The own repo_items
        has_many :repo_items, as: :owner, class_name: 'RepositoryManager::RepoItem' #, dependent: :destroy
        # The sharing repo_items
        has_many :shared_repo_items, through: :sharings, source: :repo_item, class_name: 'RepositoryManager::RepoItem'

        if Rails::VERSION::MAJOR == 4
          has_many :root_repo_items, -> { where ancestry: nil }, as: :owner, class_name: 'RepositoryManager::RepoItem'
          #scope :root_repo_items, -> { where ancestry: nil }
        else
          has_many :root_repo_items, -> { where ancestry: nil}, as: :owner, class_name: 'RepositoryManager::RepoItem'
          #scope :root_repo_items, where(where ancestry: nil)
        end

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
      def share!(repo_item, members, options = {})

        # Nested sharing are not accepted
        if !RepositoryManager.accept_nested_sharing
          # Check if no other sharing exist in the path
          if repo_item.has_nested_sharing?
            raise RepositoryManager::NestedSharingException.new("sharing failed. Another sharing already exist on the subtree or an ancestor of '#{repo_item.name}'")
          end
        end

        authorisations = get_authorisations(repo_item)

        # Here we look if the instance has the authorisation for making a sharing
        if can_share?(nil, authorisations)

          # We put the default options
          repo_item_permissions = RepositoryManager.default_repo_item_permissions
          sharing_permissions = RepositoryManager.default_sharing_permissions

          # If there is options, we have to take it
          repo_item_permissions = options[:repo_item_permissions] if options[:repo_item_permissions]
          sharing_permissions = options[:sharing_permissions] if options[:sharing_permissions]

          # Correct the item permission with accepted permissions
          repo_item_permissions = make_repo_item_permissions(repo_item_permissions, authorisations)

          sharing = RepositoryManager::Sharing.new(repo_item_permissions)
          sharing.owner = self
          sharing.creator = options[:creator]

          sharing.add_members(members, sharing_permissions)

          repo_item.sharings << sharing
          repo_item.save
          sharing
        else
          # No permission => No sharing
          raise RepositoryManager::AuthorisationException.new("sharing failed. You don't have the permission to share the repo_item '#{repo_item.name}'")
        end
      end

      def share(repo_item, members, options = {})
        begin
          share!(repo_item, members, options)
        rescue RepositoryManager::AuthorisationException, RepositoryManager::NestedSharingException
          false
        end
      end

      # Create a folder with the name (name)
      # options :
      #   :source_folder = The directory in with the folder is created
      #   :sender = The object of the sender (ex : current_user)
      # Returns the object of the folder created if it is ok
      # Returns an Exception if the folder is not created
      #     RepositoryManagerException if the name already exist
      #     AuthorisationException if the object don't have the permission
      def create_folder!(name = '', options = {})
        source_folder = options[:source_folder]
        if source_folder
          unless source_folder.is_folder?
            raise RepositoryManager::RepositoryManagerException.new("create folder failed. The source folder must be a repo_folder.")
          end
        end

        # If he want to create a folder in a directory, we have to check if he have the authorisation
        if can_create?(source_folder)

          folder = RepoFolder.new
          if name == '' || name == nil || name == false || name.blank?
            folder.name = default_folder_name(source_folder)
          else
            folder.name = name
          end
          folder.owner = self
          folder.sender = options[:sender]

          # If we are in root path we check if we can add this folder name
          if !source_folder && repo_item_name_exist_in_root?(name)
            raise RepositoryManager::RepositoryManagerException.new("create folder failed. The repo_item '#{name}' already exist in the root folder.")
          end

          unless folder.save
            raise RepositoryManager::RepositoryManagerException.new("create_folder failed. Can\'t save the folder '#{name}'.")
          end

          # It raise an error if name already exist and destroy the folder
          source_folder.add!(folder, true) if source_folder
        else
          raise RepositoryManager::AuthorisationException.new("create_folder failed. You don't have the permission to create a folder in '#{source_folder.name}'")
        end
        folder
      end

      # Like create_folder!
      # Returns false if the folder is not created instead of an exception
      def create_folder(name = '', options = {})
        begin
          create_folder!(name, options)
        rescue RepositoryManager::AuthorisationException, RepositoryManager::RepositoryManagerException
          false
        end
      end

      # Delete the repo_item
      def delete_repo_item!(repo_item)
        if can_delete?(repo_item)
          repo_item.destroy
        else
          raise RepositoryManager::AuthorisationException.new("delete_repo_item failed. You don't have the permission to delete the repo_item '#{repo_item.name}'")
        end
      end

      def delete_repo_item(repo_item)
        begin
          delete_repo_item!(repo_item)
        rescue RepositoryManager::AuthorisationException
          false
        end
      end

      # Create the file (file) in the directory (source_folder)
      # options :
      #   :source_folder = The directory in with the folder is created
      #   :sender = The object of the sender (ex : current_user)
      #
      # Param file can be a File, or a instance of RepoFile
      # Returns the object of the file created if it is ok
      # Returns an Exception if the folder is not created
      #     RepositoryManagerException if the file already exist
      #     AuthorisationException if the object don't have the permission
      def create_file!(file, options = {})
        source_folder = options[:source_folder]
        if source_folder
          unless source_folder.is_folder?
            raise RepositoryManager::RepositoryManagerException.new("create file failed. The source folder must be a repo_folder.")
          end
        end

        # If he want to create a file in a directory, we have to check if he have the authorisation
        if can_create?(source_folder)

          if file.class.name == 'RepositoryManager::RepoFile'
            repo_file = file
          elsif file.class.name == 'File' || file.class.name == 'ActionDispatch::Http::UploadedFile'
            repo_file = RepositoryManager::RepoFile.new()
            repo_file.file = file
          else # "ActionController::Parameters"
            repo_file = RepositoryManager::RepoFile.new(file)
          end

          repo_file.owner = self
          repo_file.sender = options[:sender]


          # If we are in root path we check if we can add this file name
          if !source_folder && repo_item_name_exist_in_root?(repo_file.file.identifier)
            raise RepositoryManager::RepositoryManagerException.new("create file failed. The repo_item '#{repo_file.file.identifier}' already exist in the root folder.")
          end

          unless repo_file.save
            raise RepositoryManager::RepositoryManagerException.new("create_file failed. The file can't be save")
          end

          # It raise an error if name already exist and destroy the file
          source_folder.add!(repo_file, true) if source_folder
        else
          raise RepositoryManager::AuthorisationException.new("create_file failed. You don't have the permission to create a file")
        end
        repo_file
      end

      def create_file(file, options = {})
        begin
          create_file!(file, options)
        rescue RepositoryManager::AuthorisationException, RepositoryManager::RepositoryManagerException
          false
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
        # Find if a sharing of this rep exist for the self instance or it ancestors
        else
          path_ids = repo_item.path_ids
          # Check the nearest sharing if it exist
          if s = self.sharings.where(repo_item_id: path_ids).last
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
      def download!(repo_item, options = {})
        if can_download?(repo_item)
          path = options[:path] if options[:path]

          repo_item.download!({object: self, path: path})
        else
          raise RepositoryManager::AuthorisationException.new("download failed. You don't have the permission to download the repo_item '#{repo_item.name}'")
        end
      end

      def download(repo_item, options = {})
        begin
          download!(repo_item, options)
        rescue RepositoryManager::AuthorisationException
          false
        end
      end

      # Rename the repo_item with the new_name
      def rename_repo_item!(repo_item, new_name)
        unless can_update?(repo_item)
          raise RepositoryManager::AuthorisationException.new("rename repo_item failed. You don't have the permission to update the repo_item '#{repo_item.name}'")
        end
        repo_item.rename!(new_name)
      end

      # Rename the repo_item with the new_name
      def rename_repo_item(repo_item, new_name)
        begin
          rename_repo_item!(repo_item, new_name)
        rescue RepositoryManager::AuthorisationException
          false
        end
      end

      # Move the repo_item in the target_folder
      def move_repo_item!(repo_item, target_folder)
        unless can_delete?(repo_item)
          raise RepositoryManager::AuthorisationException.new("move repo_item failed. You don't have the permission to delete the repo_item '#{repo_item.name}'")
        end
        unless can_create?(target_folder)
          raise RepositoryManager::AuthorisationException.new("move repo_item failed. You don't have the permission to create in the target_folder '#{target_folder.name}'")
        end
        # If it has the permission, we move the repo_item in the target_folder
        repo_item.move!(target_folder)
      end

      def move_repo_item(repo_item, target_folder)
        begin
          move_repo_item!(repo_item, target_folder)
        rescue RepositoryManager::RepositoryManagerException, RepositoryManager::AuthorisationException
          false
        end
      end

      # Delete the download folder of the user
      def delete_download_path
        FileUtils.rm_rf(self.get_default_download_path())
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

      # Returns true if you can edit the repo, false else
      def can_update?(repo_item, authorisations = nil)
        can_do?('update', repo_item, authorisations)
      end

      # Returns true if you can delete the repo, false else
      def can_delete?(repo_item, authorisations = nil)
        can_do?('delete', repo_item, authorisations)
      end

      ## Returns true if  it exist a sharing in the ancestors of descendant_ids of the repo_item (without itself)
      #def has_sharing?(repo_item)
      #  # An array with the ids of all ancestors and descendants
      #  ancestor_and_descendant_ids = []
      #  ancestor_and_descendant_ids << repo_item.descendant_ids if !repo_item.descendant_ids.empty?
      #  ancestor_and_descendant_ids << repo_item.ancestor_ids if !repo_item.ancestor_ids.empty?
      #
      #  # If it is a sharing, it returns true
      #  if self.sharings.where(repo_item_id: ancestor_and_descendant_ids).count > 0
      #    true
      #  else
      #    false
      #  end
      #
      #end

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
      def add_members_to!(sharing, members, options = RepositoryManager.default_sharing_permissions)
        authorisations = get_sharing_authorisations(sharing)
        if can_add_to?(sharing)
          sharing_permissions = make_sharing_permissions(options, authorisations)
          sharing.add_members(members, sharing_permissions)
        else
          raise RepositoryManager::AuthorisationException.new("add members failed. You don't have the permission to add a member in this sharing")
        end
      end

      def add_members_to(sharing, members, options = RepositoryManager.default_sharing_permissions)
        begin
          add_members_to!(sharing, members, options = RepositoryManager.default_sharing_permissions)
        rescue RepositoryManager::AuthorisationException
          false
        end
      end

        # You can here remove members in the sharing
      # Param member could be an object or an array of object
      def remove_members_from!(sharing, members)
        if can_remove_from?(sharing)
          sharing.remove_members(members)
        else
          raise RepositoryManager::AuthorisationException.new("remove members failed. You don't have the permission to remove a member on this sharing")
        end
      end

      def remove_members_from(sharing, members)
        begin
          remove_members_from!(sharing, members)
        rescue RepositoryManager::AuthorisationException
          false
        end
      end

        # Get the download path of the member
      def get_default_download_path(prefix = 'download/')
        "#{prefix}#{self.class.base_class.to_s.underscore}/#{self.id}/"
      end

      # Returns true of false if the name exist in the root path of this instance
      def repo_item_name_exist_in_root?(name)
        # add : or file : name
        #RepoItem.where(name: name).where(owner: self).where(ancestry: nil).first ? true : false
        #puts RepoItem.where('name = ? OR file = ?', name, name).where(owner: self).where(ancestry: nil).first.inspect
        #puts self.inspect

        RepoItem.where('name = ? OR file = ?', name, name).where(owner: self).where(ancestry: nil).first ? true : false

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
        # If we pass no authorisations we have to get it
        if authorisations == nil
          authorisations = get_authorisations(repo_item)
        end

        case what
          when 'read'
            authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_read] == true)
          when 'delete'
            if RepositoryManager.accept_nested_sharing
              # TODO implement to look if he can delete all the folder
            else
              authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_delete] == true)
            end
          when 'update'
            authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_update] == true)
          when 'share'
            if RepositoryManager.accept_nested_sharing
              # TODO implement to look if he can delete all the folder
            else
              authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_share] == true)
            end
          when 'create'
            if RepositoryManager.accept_nested_sharing
              # TODO implement to look if he can delete all the folder
            else
              authorisations == true || (authorisations.kind_of?(Hash) && authorisations[:can_create] == true)
            end
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

      # Put a default name if none is given
      def default_folder_name(source_folder)
        i = ''
        name = "#{I18n.t 'repository_manager.models.repo_folder.name'}"
        # We check if another item has the same name

        if source_folder
          #TODO Optimiser, récupérer tout les instances contenants le nom, puis faire la boucle (pas boucle de requete)
          # We check if another item has the same name
          until !source_folder.name_exist_in_children?(name) do
            if i == ''
              i = 1
            end
            i += 1
            name = "#{I18n.t 'repository_manager.models.repo_folder.name'} #{i}"
          end
        else
          #TODO Optimiser, récupérer tout les instances contenants le nom, puis faire la boucle (pas boucle de requete)
          # Si il n'a pas de parent, racine
          until !repo_item_name_exist_in_root?(name) do
            if i == ''
              i = 1
            end
            i += 1
            name = "#{I18n.t 'repository_manager.models.repo_folder.name'} #{i}"
          end

        end
        name
      end

    end
  end
end

ActiveRecord::Base.send :include, RepositoryManager::HasRepository