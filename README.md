WORK IN PROGRESS, but it already works !

Ruby on Rails plugin (gem) for managing repositories (files/folders/permissions/sharing). 

# RepositoryManager [![Gem Version](https://badge.fury.io/rb/repository-manager.png)](http://badge.fury.io/rb/repository-manager)

This gem add functionalities to manage repositories. Each instance (users, groups, etc..) can have it own repository (with files and folders). It can manage them (edit, remove, add, etc) and share them with other objects.

This project is based on the need for a repository manager system for [Collaide](https://github.com/facenord-sud/collaide). A system for easily create/delete files and folders in a repository. For sharing these "repo items" easily with other object with a flexible and complete permissions management.

Instead of creating my core repository manager system heavily 
dependent on our development, I'm trying to implement a generic and potent repository gem.

After looking for a good gem to use I noticed the lack of repository gems
and flexibility in them. RepositoryManager tries to be the more flexible possible.

This gem is my informatics project for the Master in [University of Lausanne (CH)](http://www.unil.ch/index.html). 

## Installation


Add to your Gemfile:

```ruby
gem 'repository-manager'
```

Then run:

```sh
$ bundle update
```

Run install script:

```sh
$ rails g repository_manager:install
```

And don't forget to migrate your database:

```sh
$ rake db:migrate
```

## Settings

You can edit the RepositoryManager settings in the initializer (/config/initializer/repository_manager.rb).

```ruby
RepositoryManager.setup do |config|

  # Default permissions that an object has on the repo_item after a sharing.
  config.default_repo_item_permissions = { can_read: true, can_create: false, can_update: false, can_delete: false, can_sharing: false }

  # Default permissions that an object has when he is added in a sharing.
  config.default_sharing_permissions = { can_add: false, can_remove: false }
  
  # Default path for generating the zip file when a user want to download a folder
  # Default is : "download/#{member.class.to_s.underscore}/#{member.id}/#{self.class.to_s.underscore}/#{self.id}/"
  #config.default_zip_path = true
end
```

For instance, if you want that a default sharing is totally free (for edit, delete, etc), just put all default parameters to `true` :

```ruby
RepositoryManager.setup do |config|
  config.default_repo_item_permissions = { can_read: true, can_create: true, can_update: true, can_delete: true, can_share: true }
  config.default_sharing_permissions = { can_add: true, can_remove: true }
end
```


See the chapter [Permissions](#permissions) for more details about the permissions.

## Preparing your models

You can choose witch model can have repository.

In your model:

```ruby
class User < ActiveRecord::Base
  has_repository
end
```

You are not limited to the User model. You can use RepositoryManager in any other model and use it in several different models. If you have Groups and Houses in your application and you want to exchange `repo_items` as if they were the same, just add `has_repository` to each one and you will be able to sharing `repo_files`/`repo_folders` groups-groups, groups-users, users-groups and users-users. Of course, you can extend it for as many classes as you need.

Example:

```ruby
class User < ActiveRecord::Base
  has_repository
end
```

```ruby
class Group < ActiveRecord::Base
  has_repository
end
```

## How to use RepositoryManager

### Introduction

A `repo_item` is an item in a repository, it can be:
- A file (`repo_file`, class name : `RepositoryManager::RepoFile`)
- A folder (`repo_folder`, class name : `RepositoryManager::RepoFolder`).

A folder can contains files and folders. Like in a real tree files and folders.

A few methods are written in those two ways :
- method(arg, options)
- method!(arg, options) (note the "!")

The two methods do the same, but the one with the "!" returns an Exception error if it is a problem (PermissionException or RepositoryManagerException for instance) and the method without "!" return false if it has a problem.

### How can I create/delete/move a repo_item (file or folder)

You just have to call the `has_repository` methods `create_file`, `create_folder`, `move_repo_item`, `copy_repo_item` or `delete_repo_item`. [Check here for all `has_repository` methods]  (https://github.com/Texicitys/repository-manager/wiki/Has_repository-methods).

```ruby
# user1 wants to create a folder in his repository

# Create a root folder on the user1 repository (you can have how many roots as you want)
source_folder = user1.create_folder('Root folder')

# user1 own repository :
#   -- 'Root folder'

# source_folder is the directory in witch user1 wants to create the folder 'The new folder'
the_new_folder = user1.create_folder('The new folder', source_folder: source_folder)

# user1 own repository :
#   |-- 'Root folder'
#   |  |-- 'The new folder'

# Now we want to add a file into the_new_folder 
# Note : user1 needs the ':can_create => true' permission in the folder : the_new_folder (else the method returns `false`).
user1.create_file(params[:file], source_folder: the_new_folder)
# OR
user1.create_file(File.open('somewhere'), source_folder: the_new_folder)
# OR
repo_file = RepositoryManager::RepoFile.new
repo_file.file = your_file
user1.create_file(repo_file, source_folder: the_new_folder)


# user1 own repository :
#   |-- 'Root folder'
#   |  |-- 'The new folder'
#   |  |  |-- 'file.txt'

# user1 want to create a file on the root of his repository
file2 = user1.create_file(params[:file2])

# user1 own repository :
#   |-- 'Root folder'
#   |  |-- 'The new folder'
#   |  |  |-- 'file.txt'
#   |-- 'file2.jpg'

# user1 want to create a folder on the root of his repository
test_folder = user1.create_folder('Test folder')

# user1 own repository :
#   |-- 'Root folder'
#   |  |-- 'The new folder'
#   |  |  |-- 'file.txt'
#   |-- 'file2.jpg'
#   |-- 'Test folder'

# user1 want to move 'The new folder' in 'Test folder'
user1.move_repo_item(the_new_folder, test_folder)

# user1 own repository :
#   |-- 'Root folder'
#   |-- 'file2.jpg'
#   |-- 'Test folder'
#   |  |-- 'The new folder'
#   |  |  |-- 'file.txt'

# user1 want to rename 'The new folder' to 'The renamed folder' (it also can change the name of a file)
user1.rename_repo_item(the_new_folder, 'The renamed folder')

# user1 own repository :
#   |-- 'Root folder'
#   |-- 'file2.jpg'
#   |-- 'Test folder'
#   |  |-- 'The renamed folder'
#   |  |  |-- 'file.txt'

# user1 want to copy 'Root folder' into 'Test folder'
user1.copy_repo_item(source_folder, test_folder)

# user1 own repository :
#   |-- 'Root folder'
#   |-- 'file2.jpg'
#   |-- 'Test folder'
#   |  |-- 'Root folder'
#   |  |-- 'The renamed folder'
#   |  |  |-- 'file.txt'

# Delete a repo_item
# Note : user1 needs the ':can_delete => true' permission in the folder : the_new_folder (else the method returns `false`).
user1.delete_repo_item(test_folder)

# user1 own repository :
#   |-- 'Root folder'
#   |-- 'file2.jpg'

user1.delete_repo_item(file2)

# user1 own repository :
#   |-- 'Root folder'

```

If a user (sender of the item) send a file or folder into a group (owner of this item), you can specify the owner and the sender like this :

```ruby
# user1 wants to create a folder and a file into group1
folder = group1.create_folder('Folder created by user1', sender: user1)

folder.owner # Returns group1
folder.sender # Returns user1

# Now he send the file into the folder
file = group1.create_file(params[:file], source_folder: folder, sender: user1)

file.owner # Returns group1
file.sender # Returns user1

# If you don't specify the sender, the owner becomes the sender

```

WARNING : There is no verification if the user1 has the permission to create a file or folder into this group. You have to check this in your controller ! The fact that user1 is the sender of this folder gives him NO PERMISSION on it !

### How can I share a repo_item (file/folder)

Now, user1 want to share his folder 'The new folder' with a Group object `group1` and another User object `user2`. You can use the `has_repository` method `share(repo_item, member, options = nil)`.


```ruby
# user1 wants to share the_new_folder with group1 and user2

members = []
# You can add other instances (who `has_repository`) in this array to share with more than one instance
members << group1
members << user2

sharing = user1.share(the_new_folder, members)

# If you want to customize your sharing options, you can do it like this:
options = {sharing_permissions: {can_add: true, can_remove: true}, repo_item_permissions: {can_read: true, can_create: true, can_update: true, can_delete: true, can_share: true}}

sharing = user1.share(the_new_folder, members, options)
```

`repo_item_permissions` specifies what kind of permissions you give on the repo_item in a specific sharing.

`sharing_permissions` specifies if the member of the sharing can add or remove other members in this sharing.

See the chapter [Permissions](#permissions) for more details.

### Repository Manager and the nested sharing

Repository Manager actually don't accept nested sharing.

```ruby

parent = @user1.create_folder('Parent')
nested = @user1.create_folder('Nested', parent)
children = @user1.create_folder('Children', nested)

# @user1 own repository :
#   |-- 'Parent'
#   |  |-- 'Nested'
#   |  |  |-- 'Children'

@user1.share(nested, @user2)

nested.can_be_shared_without_nesting? # Returns true (because `nested` is shared but there exist no nested sharing)
parent.can_be_shared_without_nesting? # Returns false (because there is a sharing on one of his descendants)
children.can_be_shared_without_nesting? # Returns false (because there is a sharing on one of his ancestors)

# Here we can't share 'Parent' or 'Children' because it already exist a nested sharing.
@user1.share(parent, @user2) # Returns false
@user1.share!(parent, @user2) # Raise a NestedSharingException (note the "!")
@user1.share!(children, @user2) # Raise a NestedSharingException  (note the "!")
```

### How can I see my repo_items

You can have two kind of repo_items: 
- Your own repo_items
- The repo_items shared with you.

You can get all the items of only these who are in the root.

```ruby
# user1 want to get his own repository
user1.repo_items.all # => You get the repo_items that user1 has created

# user2 want to get his root repo_items 
user2.root_repo_items.all

# user2 want to get his shared repo_items
user2.shared_repo_items.all

# user2 want to get his root shared repo_items
user2.root_shared_repo_items.all

```

If you only want to have the folders or the files, you can do it like that:

```ruby
# return only the own folders of user1
user1.repo_items.folders.to_a # => You get the repo_folders that user1 has created

# user2 want to get his shared repo_files
user2.shared_repo_items.files.to_a
```

Recall: a repo_item can be:
- A file
- A folder

```ruby
# We want to know if the object repo_item is a file or a folder:
if repo_item.is_folder
  repo_item.name #=> Returns the name of the folder (for instance : 'New folder').
elsif repo_item.is_file?
  repo_item.name #=> Returns the name of the file (for instance : 'file.png').
  # Here is the file
  repo_item.file.url # => '/url/to/stored_file.png'
  repo_item.file.current_path # => 'path/to/stored_file.png'
end
```

For file details, more infos on [the documentation of the carrierwave gem](https://github.com/carrierwaveuploader/carrierwave).


### How can I manage a sharing


If it has the permission, an object can add members to a sharing.

```ruby
# user1 want to add members to his sharing
# NOTE: The action is done only if user1 has the ':can_add' sharing permission.
user1.can_add_to?(sharing) # => true

# Add members
members = []
members << user3
members << group2
...

user1.add_members_to(sharing, members)

# You can change the default sharing permissions options for the new members :
options = {can_add: true, can_remove: false}
user1.add_members_to(sharing, members, options)


# Here user3 and group2 can add members in this sharing, but they can't remove a member.
group2.can_add_to?(sharing) # => true
group2.can_remove_from?(sharing) # => false

# If user2 (the user who was add with the sharing permissions : {can_add: true, can_remove: false}) add a member in the sharing, he can choose if the permission ':can_add' is true or false, but he can't put ':can_remove' to true (because he don't have this permission himself).
```

If an object has the permission, it can remove members from a sharing, else the method return `false` (or raise an PermissionException if you user the `remove_members_from!` method).

```ruby
# user1 want to remove group2 from the sharing `sharing`
user1.remove_members_from(sharing, group2) # The second parameter can be an object or an array of object
```

You can directly work with the `sharing`. Be careful, there is NO permission control !

```ruby
# Add a member to the sharing `sharing`
sharing.add_members(member)
# Or with options :
sharing.add_members(member, {can_add: true, can_remove: false})


# Remove members from the sharing
sharing.remove_members([user2, group1])
```

### Permissions

#### Repository permissions

The owner of a `repo_item` (file or folder) has all the permissions on it. When he share this `repo_item`, he can choose what permission he gives to the share. The permissions are :
- `can_read?(repo_item)` : The member can read (=download) this file/folder.
- `can_create?(repo_item)` : Can create in the repo_item (Note: if repo_item is nil (= own root), always true).
- `can_update?(repo_item)` : Can update a repo_item (ex: rename).
- `can_delete?(repo_item)` : Can delete a repo_item.
- `can_share?(repo_item)` : Can share a repo_item.

To check if a user has one of this permission, you just have to write : `user1.can_read?(repo_item)`, `user1.can_share?(repo_item)`, etc (it returns `true` or `false`).

NOTICE : An object who can share a repo_item, can't set new permissions that it doesn't have.
For instance: `user3` has a `sharing` of `repo_item1` in which it `:can_delete => false` and `:can_share => true`. He can share `repo_item1` with `user4`, but he can't put `:can_delete => true` in the `repo_item_permission` of this new share.

You can get all the permissions of an `object` in a `repo_item` with this method: `object.get_permissions(repo_item)`

```ruby
      # Gets the repo permissions
      # Return false if the entity has not the permission to share this rep
      # Return true if the entity can share this rep with all the permissions
      # Return an Array if the entity can share but with restriction
      # Return true if the repo_item is nil (he as all permissions on his own rep)
      def get_permissions(repo_item = nil)
        [...]
      end
```

#### Sharing permissions

You can manage the permissions of a member in a sharing. The owner of the sharing has all the permissions. The sharing permissions are:
- `can_add_to?(sharing)` : The member can add a new instance in this sharing.
- `can_remove_from?(sharing)` : Can remove an instance from this sharing.

To check if the object can add or remove an instance in the sharing, just write : `group1.can_add_to?(sharing)` or `group1.can_remove_from?(sharing)` (it returns `true` or `false`).

Like the repo_item permissions, you can get the sharing permissions of an `object` in a `sharing` with : `object.get_sharing_permissions(sharing)`.

### Download a repository

RepositoryManager make the download of a `repo_item` easy. If the user want to download a file, use the `has_repository` method : `download`. This method returns you the path of the file (if the user `can_read` it).

If the `repo_item` is a file, the method returns you the path of this file.
If the `repo_item` is a folder, it automatically generates a zip file with all the constant that the user `can_read`. The method returns the path of this zip file.

```ruby
# user1 want to download the_file
path_to_file = user1.download(the_file)
# don't forget to specify the name of the file (it could have been changed since uploaded)
send_file path_to_file, filename: the_file.name
```

```ruby
# user1 want to download the_folder
path_to_zip = user1.download(the_folder)

# Then you can do what you want with this path, you can use the send_file method from rails in your controller
send_file path_to_zip

# Don't forget to delete the zip file after the user has downloaded it (when his session end for instance)
# I created a method who delete all the download file path of an object (here `user1` for instance)
user1.delete_download_path()
```

You can directly download the folder (without permission control):

```ruby
# Directly download all the folder
path = the_folder.download

# You can delete the zip file with
the_folder.delete_zip
```

### Errors handling

When an error happen, you (and the user also) want to know what was the source of this problem. I tried to make it the most simple as possible.

For the two `has_repository` methods `create_file` and `create_folder`, the errors are pushed into the `options` hash parameter with the key `errors` (`options[:errors]`)


```ruby
# We want to redirect back with the notice 'Folder created' if the folder is created, and show the error(s) otherwise
options = {source_folder: repo_item, sender: current_user}
if @item = @group.create_folder(params[:repo_folder][:name], options)
    redirect_to back, notice: 'Folder created'
else
    redirect_to back, alert: options[:errors].first # Contains the first text message error

options[:errors] # Contains array of errors

# Same for create_file
options = {source_folder: repo_item, sender: current_user}
if @item = @group.create_file(params[:repo_file][:file], options)
    redirect_to back, notice: 'File created'
else
    redirect_to back, alert: options[:errors].first # Contains the first text message(s) error(s)

options[:errors] # Contains array of errors
```

For the other `has_repository` methods, the error is added to the first object passed in parameter (for instance: `repo_item` or `sharing`)


```ruby
# We want to catch the error if it has one
if @group.delete_repo_item(@repo_item)
    redirect_to :back, notice: 'Item deleted'
else
    # repo_item.errors ==> Contains the errors
    redirect_to :back, alert: repo_item.errors.messages[:delete].first
end
```


## TODO

- Test the rename file method
- Write the methods : share_link.
- Snapshot the file if possible
- Versioning
- ...


## License

This project rocks and uses MIT-LICENSE.

Created by Yves Baumann.

