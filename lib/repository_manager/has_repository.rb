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

        if Rails::VERSION::MAJOR >= 4
          has_many :root_repo_items, -> { where ancestry: nil }, as: :owner, class_name: 'RepositoryManager::RepoItem'
          has_many :root_shared_repo_items,  -> { where ancestry: nil }, through: :sharings, source: :repo_item, class_name: 'RepositoryManager::RepoItem'
        else
          has_many :root_repo_items, where(ancestry: nil), as: :owner, class_name: 'RepositoryManager::RepoItem'
          has_many :root_shared_repo_items, where(ancestry: nil), through: :sharings, source: :repo_item, class_name: 'RepositoryManager::RepoItem'
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
      def share_repo_item!(repo_item, members, options = {})

        # Nested sharing are not accepted
        if !RepositoryManager.accept_nested_sharing
          # Check if no other sharing exist in the path
          unless repo_item.can_be_shared_without_nesting?
            repo_item.errors.add(:sharing, I18n.t('repository_manager.errors.sharing.create.nested_sharing'))
            raise RepositoryManager::NestedSharingException.new("sharing failed. Another sharing already exist on the subtree or an ancestor of '#{repo_item.name}'")
          end
        end

        permissions = get_permissions(repo_item)

        # Here we look if the instance has the permission for making a sharing
        if can_share?(nil, permissions)

          # We put the default options
          repo_item_permissions = RepositoryManager.default_repo_item_permissions
          sharing_permissions = RepositoryManager.default_sharing_permissions

          # If there is options, we have to take it
          repo_item_permissions = options[:repo_item_permissions] if options[:repo_item_permissions]
          sharing_permissions = options[:sharing_permissions] if options[:sharing_permissions]

          # Correct the item permission with accepted permissions
          repo_item_permissions = make_repo_item_permissions(repo_item_permissions, permissions)

          sharing = RepositoryManager::Sharing.new(repo_item_permissions)
          sharing.owner = self
          sharing.creator = options[:creator]

          sharing.add_members(members, sharing_permissions)

          repo_item.sharings << sharing
          repo_item.save!
          sharing
        else
          # No permission => No sharing
          repo_item.errors.add(:sharing, I18n.t('repository_manager.errors.sharing.create.no_permission'))
          raise RepositoryManager::PermissionException.new("sharing failed. You don't have the permission to share the repo_item '#{repo_item.name}'")
        end
      end

      def share_repo_item(repo_item, members, options = {})
        begin
          share_repo_item!(repo_item, members, options)
        rescue RepositoryManager::PermissionException, RepositoryManager::NestedSharingException, RepositoryManager::RepositoryManagerException
          false
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          repo_item.errors.add(:sharing, I18n.t('repository_manager.errors.sharing.create.not_created'))
          false
        end
      end

      # Create a folder with the name (name)
      # options :
      #   :source_folder = The directory in with the folder is created
      #   :sender = The object of the sender (ex : current_user)
      #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')
      # Returns the object of the folder created if it is ok
      # Returns an Exception if the folder is not created
      #     RepositoryManagerException if the name already exist
      #     PermissionException if the object don't have the permission
      def create_folder!(name = '', options = {})
        source_folder = options[:source_folder]
        if source_folder
          unless source_folder.is_folder?
            raise RepositoryManager::RepositoryManagerException.new("create folder failed. The source folder must be a repo_folder.")
          end
        end

        !!options[:overwrite] == options[:overwrite] ? overwrite = options[:overwrite] : overwrite = RepositoryManager.auto_overwrite_item

        # If he want to create a folder in a directory, we have to check if he have the permission
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
          if !source_folder
            repo_item_with_same_name = get_item_in_root_by_name(name)
            if repo_item_with_same_name && !overwrite
              raise RepositoryManager::ItemExistException.new("create folder failed. The repo_item '#{name}' already exist in the root folder.")
            elsif repo_item_with_same_name && overwrite
              # We destroy the item with same name for overwrite it
              repo_item_with_same_name.destroy!
            end
          else
            # It raise an error if name already exist and destroy the folder
            source_folder.add!(folder, do_not_save: true, overwrite: overwrite)
          end

          folder.save!
        else
          raise RepositoryManager::PermissionException.new("create_folder failed. You don't have the permission to create a folder in '#{source_folder.name}'")
        end
        folder
      end

      # Like create_folder!
      # Returns false if the folder is not created instead of an exception
      def create_folder(name = '', options = {})
        options[:errors] = []
        begin
          create_folder!(name, options)
        rescue RepositoryManager::PermissionException
          options[:errors].push(I18n.t'repository_manager.errors.repo_item.repo_folder.create.no_permission')
          false
        rescue RepositoryManager::ItemExistException
          options[:errors].push(I18n.t'repository_manager.errors.repo_item.repo_folder.item_exist')
          false
        rescue RepositoryManager::RepositoryManagerException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          options[:errors].push(I18n.t'repository_manager.errors.repo_item.repo_folder.create.not_created')
          false
        end
      end

      # Delete the repo_item
      def delete_repo_item!(repo_item)
        if can_delete?(repo_item)
          repo_item.destroy
        else
          repo_item.errors.add(:delete, I18n.t('repository_manager.errors.repo_item.delete.no_permission'))
          raise RepositoryManager::PermissionException.new("delete_repo_item failed. You don't have the permission to delete the repo_item '#{repo_item.name}'")
        end
      end

      def delete_repo_item(repo_item)
        begin
          delete_repo_item!(repo_item)
        rescue RepositoryManager::PermissionException
          false
        end
      end

      # Create the file (file) in the directory (source_folder)
      # options :
      #   :source_folder = The directory in with the folder is created
      #   :sender = The object of the sender (ex : current_user)
      #   :filename = The name of the file (if you want to rename it directly)
      #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')

      # Param file can be a File, or a instance of RepoFile
      # Returns the object of the file created if it is ok
      # Returns an Exception if the folder is not created
      #     RepositoryManagerException if the file already exist
      #     PermissionException if the object don't have the permission
      def create_file!(file, options = {})
        source_folder = options[:source_folder]
        if source_folder
          unless source_folder.is_folder?
            raise RepositoryManager::RepositoryManagerException.new("create file failed. The source folder must be a repo_folder.")
          end
        end

        !!options[:overwrite] == options[:overwrite] ? overwrite = options[:overwrite] : overwrite = RepositoryManager.auto_overwrite_item

        # If he want to create a file in a directory, we have to check if he have the permission
        if can_create?(source_folder)

          if file.class.name == 'RepositoryManager::RepoFile'
            repo_file = file
          elsif file.class.name == 'File' || file.class.name == 'ActionDispatch::Http::UploadedFile'
            repo_file = RepositoryManager::RepoFile.new()
            repo_file.file = file
          else # "ActionController::Parameters"
            repo_file = RepositoryManager::RepoFile.new(file)
          end

          options[:filename] ? file_name = options[:filename] : file_name = repo_file.file.url.split('/').last

          repo_file.name = file_name
          repo_file.owner = self
          repo_file.sender = options[:sender]

          # If we are in root path we check if we can add this file name
          if !source_folder
            repo_item_with_same_name = get_item_in_root_by_name(file_name)
            if repo_item_with_same_name && !overwrite
              raise RepositoryManager::ItemExistException.new("create file failed. The repo_item '#{file_name}' already exist in the root folder.")
            elsif repo_item_with_same_name && overwrite
              #We do not destroy, we update it !

              # We update the file
              if file.class.name == 'RepositoryManager::RepoFile'
                repo_item_with_same_name.file = file.file
              elsif file.class.name == 'File' || file.class.name == 'ActionDispatch::Http::UploadedFile'
                repo_item_with_same_name.file = file
              else # "ActionController::Parameters"
                repo_item_with_same_name.assign_attributes(file)
              end

              repo_item_with_same_name.sender = options[:sender]
              #p "source: updates the file #{repo_item_with_same_name.name}"
              repo_file = repo_item_with_same_name
            end
          else
            # It raise an error if name already exist and destroy the file
            repo_file = source_folder.add!(repo_file, do_not_save: true, overwrite: overwrite)
          end
          repo_file.save!
        else
          raise RepositoryManager::PermissionException.new("create_file failed. You don't have the permission to create a file")
        end
        repo_file
      end

      def create_file(file, options = {})
        options[:errors] = []
        begin
          create_file!(file, options)
        rescue RepositoryManager::PermissionException
          options[:errors].push(I18n.t'repository_manager.errors.repo_item.repo_file.create.no_permission')
          false
        rescue RepositoryManager::ItemExistException
          options[:errors].push(I18n.t'repository_manager.errors.repo_item.repo_file.item_exist')
          false
        rescue RepositoryManager::RepositoryManagerException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          options[:errors].push(I18n.t'repository_manager.errors.repo_item.repo_file.create.not_created')
          false
        end
      end

      # Gets the repo permissions
      # Return false if the entity has not the permission to share this rep
      # Return true if the entity can share this rep with all the permissions
      # Return an Array if the entity can share but with restriction
      # Return true if the repo_item is nil (he as all permissions on his own rep)
      def get_permissions(repo_item = nil)
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

      # Rename the repo_item with the new_name
      def rename_repo_item!(repo_item, new_name)
        unless can_update?(repo_item)
          repo_item.errors.add(:rename, I18n.t('repository_manager.errors.repo_item.rename.no_permission'))
          raise RepositoryManager::PermissionException.new("rename repo_item failed. You don't have the permission to update the repo_item '#{repo_item.name}'")
        end
        repo_item.rename!(new_name)
      end

      # Rename the repo_item with the new_name
      def rename_repo_item(repo_item, new_name)
        begin
          rename_repo_item!(repo_item, new_name)
        rescue RepositoryManager::PermissionException
          false
        end
      end

      # Move the repo_item
      # options
      #   :source_folder =>  move into this source_folder
      #   if :source_folder == nil, move to the root
      #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')
      def move_repo_item!(repo_item, options = {})
        !!options[:overwrite] == options[:overwrite] ? overwrite = options[:overwrite] : overwrite = RepositoryManager.auto_overwrite_item
        target = options[:source_folder]

        if !can_read?(repo_item)
          repo_item.errors.add(:move, I18n.t('repository_manager.errors.repo_item.move.no_permission'))
          raise RepositoryManager::PermissionException.new("move repo_item failed. You don't have the permission to read the repo_item '#{repo_item.name}'")
        end
        # If we want to change the owner we have to have the can_delete permission
        if target
          # If want to change the owner, we have to check if we have the permission
          if target.owner != repo_item.owner && !can_delete?(repo_item)
            repo_item.errors.add(:move, I18n.t('repository_manager.errors.repo_item.move.no_permission'))
            raise RepositoryManager::PermissionException.new("move repo_item failed. You don't have the permission to delete the repo_item '#{repo_item.name}'")
          end
          # If we don't want to change the owner, we look if we can_update
          if target.owner == repo_item.owner && !can_update?(repo_item)
            repo_item.errors.add(:move, I18n.t('repository_manager.errors.repo_item.move.no_permission'))
            raise RepositoryManager::PermissionException.new("move repo_item failed. You don't have the permission to update the '#{repo_item.name}'")
          end
          # We check if we can_create in the source_folder
          unless can_create?(target)
            repo_item.errors.add(:move, I18n.t('repository_manager.errors.repo_item.move.no_permission'))
            raise RepositoryManager::PermissionException.new("move repo_item failed. You don't have the permission to create in the source_folder '#{options[:source_folder].name}'")
          end
        else
          # Else if there is no source_folder, we check if we can delete the repo_item, if the owner change
          if self != repo_item.owner && !can_delete?(repo_item)
            repo_item.errors.add(:move, I18n.t('repository_manager.errors.repo_item.move.no_permission'))
            raise RepositoryManager::PermissionException.new("move repo_item failed. You don't have the permission to delete the repo_item '#{repo_item.name}'")
          end
        end
        # If it has the permission, we move the repo_item in the source_folder
        repo_item.move!(source_folder: target, overwrite: overwrite)
      end

      def move_repo_item(repo_item, options = {})
        begin
          move_repo_item!(repo_item, options)
        rescue RepositoryManager::PermissionException, RepositoryManager::ItemExistException
          false
        rescue RepositoryManager::RepositoryManagerException, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          repo_item.errors.add(:move, I18n.t('repository_manager.errors.repo_item.move.not_moved'))
          false
        end
      end

      # Copy the repo_item in the source_folder or in own root
      # options
      #   :source_folder => the folder in witch we want to copy the repo item
      #   :sender => the new sender (by default => still the old sender)
      #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')
      def copy_repo_item!(repo_item, options = {})
        !!options[:overwrite] == options[:overwrite] ? overwrite = options[:overwrite] : overwrite = RepositoryManager.auto_overwrite_item

        target = options[:source_folder]

        unless can_read?(repo_item)
          repo_item.errors.add(:copy, I18n.t('repository_manager.errors.repo_item.copy.no_permission'))
          raise RepositoryManager::PermissionException.new("copy repo_item failed. You don't have the permission to read the repo_item '#{repo_item.name}'")
        end

        if target && !can_create?(target)
          repo_item.errors.add(:copy, I18n.t('repository_manager.errors.repo_item.copy.no_permission'))
          raise RepositoryManager::PermissionException.new("copy repo_item failed. You don't have the permission to create in the source_folder '#{target.name}'")
        end

        # The new owner
        #if target
        #  owner = target.owner
        #else
          owner = self
        #end

        # If it has the permission, we copy the repo_item in the source_folder
        repo_item.copy!(source_folder: target, owner: owner, sender: options[:sender], overwrite: overwrite)
      end

      def copy_repo_item(repo_item, options = {})
        begin
          copy_repo_item!(repo_item, options)
        rescue RepositoryManager::PermissionException, RepositoryManager::ItemExistException
          false
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          repo_item.errors.add(:copy, I18n.t('repository_manager.errors.repo_item.copy.not_copied'))
          false
        end
      end

      # Download a repo_item if the object can_read it
      # If it is a file, he download the file
      # If it is a folder, we check witch repo_item is in it, and witch he can_read
      # We zip all the content that the object has access.
      # options
      #   :path => 'path/to/zip'
      def download_repo_item!(repo_item, options = {})
        if can_download?(repo_item)
          path = options[:path] if options[:path]

          repo_item.download!({object: self, path: path})
        else
          repo_item.errors.add(:download, I18n.t('repository_manager.errors.repo_item.download.no_permission'))
          raise RepositoryManager::PermissionException.new("download failed. You don't have the permission to download the repo_item '#{repo_item.name}'")
        end
      end

      def download_repo_item(repo_item, options = {})
        begin
          download_repo_item!(repo_item, options)
        rescue RepositoryManager::PermissionException
          false
        end
      end

      # Delete the download folder of the user
      def delete_download_path
        FileUtils.rm_rf(self.get_default_download_path())
      end

      # Unzip the compressed file and create the repo_items
      # options
      #   :source_folder = the folder in witch you unzip this archive
      #   :sender = the sender of the item (if you don't specify sender.. The sender is still the same)
      #   :overwrite = overwrite an item with the same name (default : see config 'auto_overwrite_item')
      def unzip_repo_item!(repo_item, options = {})
        target = options[:source_folder]

        unless can_read?(repo_item)
          repo_item.errors.add(:unzip, I18n.t('repository_manager.errors.repo_item.unzip.no_permission'))
          raise RepositoryManager::PermissionException.new("unzip repo_file failed. You don't have the permission to read the repo_file '#{repo_item.name}'")
        end

        if target && !can_create?(target)
          repo_item.errors.add(:unzip, I18n.t('repository_manager.errors.repo_item.unzip.no_permission'))
          raise RepositoryManager::PermissionException.new("unzip repo_file failed. You don't have the permission to create in the source_folder '#{target.name}'")
        end

        if !target
          parent = repo_item.parent
          if parent && !can_create?(parent)
            repo_item.errors.add(:unzip, I18n.t('repository_manager.errors.repo_item.unzip.no_permission'))
            raise RepositoryManager::PermissionException.new("unzip repo_file failed. You don't have the permission to create in the source_folder '#{parent.name}'")
          end
        end

        repo_item.unzip!(source_folder: target, owner: self, sender: options[:sender], overwrite: options[:overwrite])
      end

      def unzip_repo_item(repo_item, options = {})
        begin
          unzip_repo_item!(repo_item, options)
        rescue RepositoryManager::PermissionException, RepositoryManager::ItemExistException
          false
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
          repo_item.errors.add(:copy, I18n.t('repository_manager.errors.repo_item.unzip.not_unzipped'))
          false
        end
      end

      # Return the permissions of the sharing (can_add, can_remove)
      def get_sharing_permissions(sharing)
        sharing.get_permissions(self)
      end

      # Return true if you can share the repo, else false
      # You can give the permissions or the repo_item as params
      def can_share?(repo_item, permissions = nil)
        can_do?('share', repo_item, permissions)
      end

      # Return true if you can read the repo, else false
      def can_read?(repo_item, permissions = nil)
        can_do?('read', repo_item, permissions)
      end

      # Return true if you can download the repo, else false
      # Read = Download for the moment
      def can_download?(repo_item, permissions = nil)
        can_do?('read', repo_item, permissions)
      end

      # Return true if you can create in the repo, false else
      def can_create?(repo_item, permissions = nil)
        can_do?('create', repo_item, permissions)
      end

      # Returns true if you can edit the repo, false else
      def can_update?(repo_item, permissions = nil)
        can_do?('update', repo_item, permissions)
      end

      # Returns true if you can delete the repo, false else
      def can_delete?(repo_item, permissions = nil)
        can_do?('delete', repo_item, permissions)
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

      # Add new members in the sharing
      # Param member could be an object or an array of object
      def add_members_to!(sharing, members, options = RepositoryManager.default_sharing_permissions)
        permissions = get_sharing_permissions(sharing)
        if can_add_to?(sharing)
          sharing_permissions = make_sharing_permissions(options, permissions)
          sharing.add_members(members, sharing_permissions)
        else
          sharing.errors.add(:add, I18n.t('repository_manager.errors.sharing.add.no_permission'))
          raise RepositoryManager::PermissionException.new("add members failed. You don't have the permission to add a member in this sharing")
        end
      end

      def add_members_to(sharing, members, options = RepositoryManager.default_sharing_permissions)
        begin
          add_members_to!(sharing, members, options = RepositoryManager.default_sharing_permissions)
        rescue RepositoryManager::PermissionException
          false
        end
      end

      # Remove members in the sharing
      # Param member could be an object or an array of object
      def remove_members_from!(sharing, members)
        if can_remove_from?(sharing)
          sharing.remove_members(members)
        else
          sharing.errors.add(:remove, I18n.t('repository_manager.errors.sharing.remove.no_permission'))
          raise RepositoryManager::PermissionException.new("remove members failed. You don't have the permission to remove a member on this sharing")
        end
      end

      def remove_members_from(sharing, members)
        begin
          remove_members_from!(sharing, members)
        rescue RepositoryManager::PermissionException
          false
        end
      end

        # Get the download path of the member
      def get_default_download_path(prefix = "#{Rails.root.join('download')}/")
        "#{prefix}#{self.class.base_class.to_s.underscore}/#{self.id}/"
      end

      # Returns true of false if the name exist in the root path of this instance
      def repo_item_name_exist_in_root?(name)
        get_item_in_root_by_name(name) ? true : false
      end

      def get_item_in_root_by_name(name)
        RepoItem.where('name = ?', name).where(owner: self).where(ancestry: nil).first
      end

      # Get or create the folder with this name
      # options
      #   :sender = the sender of the item
      def get_or_create_by_path_array(path_array, options = {})
        name = path_array[0]
        children = self.get_item_in_root_by_name(name)
        unless children
          children = RepositoryManager::RepoFolder.new(name: name)
          children.owner = self
          children.sender = options[:sender]
          children.save!
        end
        # remove the first element
        path_array.shift
        children = children.get_or_create_by_path_array(path_array, sender: options[:sender], owner: self)
        children
      end

      private

      # Return if you can do or not this action in the sharing
      def can_do_to?(what, sharing, permissions = nil)
        if permissions == nil
          permissions = sharing.get_permissions(self)
        end
        case what
          when 'add'
            permissions == true || (permissions.kind_of?(Hash) && permissions[:can_add] == true)
          when 'remove'
            permissions == true || (permissions.kind_of?(Hash) && permissions[:can_remove] == true)
        end
      end

      # reflexion: can_do?(what, options)
      # options
      #   hash : permissions hash
      #   class: RepoItem => get_permissions
      #   class: has_repository => regarder si on peu déplacer dans root (question: non pas possible ?)

      # Return if you can do or not this action (what)
      def can_do?(what, repo_item, permissions = nil)
        # If we pass no permissions we have to get it
        if permissions == nil
          permissions = get_permissions(repo_item)
        end
        case what
          when 'read'
            permissions == true || (permissions.kind_of?(Hash) && permissions[:can_read] == true)
          when 'delete'
            if RepositoryManager.accept_nested_sharing
              # TODO implement to look if he can delete all the folder
            else
              permissions == true || (permissions.kind_of?(Hash) && permissions[:can_delete] == true)
            end
          when 'update'
            permissions == true || (permissions.kind_of?(Hash) && permissions[:can_update] == true)
          when 'share'
            if RepositoryManager.accept_nested_sharing
              # TODO implement to look if he can delete all the folder
            else
              permissions == true || (permissions.kind_of?(Hash) && permissions[:can_share] == true)
            end
          when 'create'
            if RepositoryManager.accept_nested_sharing
              # TODO implement to look if he can delete all the folder
            else
              permissions == true || (permissions.kind_of?(Hash) && permissions[:can_create] == true)
            end
          else
            false
        end

      end

      # Correct the repo_item_permissions with the permissions
      def make_repo_item_permissions(wanted_permissions, permissions)
        # If it is an array, we have restriction in the permissions
        if permissions.kind_of?(Hash) && wanted_permissions
          # Built the sharing with the accepted permissions
          # We remove the permission if we can't sharing it
          if wanted_permissions[:can_read] == true && permissions[:can_read] == false
            wanted_permissions[:can_read] = false
          end
          if wanted_permissions[:can_create] == true && permissions[:can_create] == false
            wanted_permissions[:can_create] = false
          end
          if wanted_permissions[:can_update] == true && permissions[:can_update] == false
            wanted_permissions[:can_update] = false
          end
          if wanted_permissions[:can_delete] == true && permissions[:can_delete] == false
            wanted_permissions[:can_delete] = false
          end
          if wanted_permissions[:can_share] == true && permissions[:can_share] == false
            wanted_permissions[:can_share] = false
          end
        end
        return wanted_permissions
      end

      # Correct the sharing_permissions with the permissions
      def make_sharing_permissions(wanted_permissions, permissions)
        # If it is an array, we have restriction in the permissions
        if permissions.kind_of?(Hash) && wanted_permissions
          # Built the sharing with the accepted permissions
          # We remove the permission if we can't share it
          if wanted_permissions[:can_add] == true && permissions[:can_add] == false
            wanted_permissions[:can_add] = false
          end
          if wanted_permissions[:can_remove] == true && permissions[:can_remove] == false
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
          folders = source_folder.children
        else
          folders = RepositoryManager::RepoFolder.where('name LIKE ?', "%#{name}%").where(owner: self).where(ancestry: nil).to_a
        end
        # Si il n'a pas de parent, racine
        until !name_exist_in_array(folders, name) do
          if i == ''
            i = 1
          end
          i += 1
          name = "#{I18n.t 'repository_manager.models.repo_folder.name'} #{i}"
        end
        name
      end

      def name_exist_in_array(folders, name)
        folders.each do |folder|
          if folder.name == name
            return true
          end
        end
        return false
      end

    end
  end
end

ActiveRecord::Base.send :include, RepositoryManager::HasRepository
