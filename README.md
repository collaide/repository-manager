WORK IN PROGRESS, but it already works !

Ruby on Rails plugin (gem) for managing repositories (files/folders/permissions/sharing). 

# RepositoryManager

This gem add fonctionalities to manage repositories. Each instance (users, groups, etc..) can have it own repository (with files and folders). It can manage them (edit, remove, add, etc) and share them with other objects.

This project is based on the need for a repository manager system for [Collaide](https://github.com/facenord-sud/collaide). A system for easily create/delete files and folders in a repository. For sharing these "repo items" easily with other object with a flexible and complete authorisations management.

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
end
```

For instance, if you want that a default sharing is totaly free, just put all default parameters to `true` :
```ruby
RepositoryManager.setup do |config|
  config.default_repo_item_permissions = { can_read: true, can_create: true, can_update: true, can_delete: true, can_share: true }
  config.default_sharing_permissions = { can_add: true, can_remove: true }
end
```


See the chapter [Authorisations](#authorisations) for more details about the permissions.

## Preparing your models

You can choose wich model can have repository. 

In your model:

```ruby
class User < ActiveRecord::Base
  has_repository
end
```

You are not limited to the User model. You can use RepositoryManager in any other model and use it in serveral different models. If you have Groups and Houses in your application and you want to exchange `repo_items` as if they were the same, just add `has_repository` to each one and you will be able to sharing `repo_files`/`repo_folders` groups-groups, groups-users, users-groups and users-users. Of course, you can extend it for as many classes as you need.

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
- A file (`repo_file`, class name : `RepoFile`)
- A folder (`repo_folder`, class name : `RepoFolder`).

A folder can contains files and folders. Like in a real tree files and folders.

### How can I create/delete a repo_item (file or folder)

You just have to call the `has_repository` methods `create_file`, `create_folder`, or `delete_repo_item`.

```ruby
# user1 wants to create a folder in his repository

# Create a root folder on the user1 repository (you can have how many roots as you want)
source_folder = user1.create_folder('Root folder')

# user1 own repository :
#   -- 'Root folder'

# source_folder is the directory in wich user1 wants to create the folder 'The new folder'
the_new_folder = user1.create_folder('The new folder', source_folder)

# user1 own repository :
#   |-- 'Root folder'
#   |  |-- 'The new folder'

# Now we want to add a file into the_new_folder 
# Note : user1 needs the ':can_create => true' permission in the folder : the_new_folder (else the method returns `false`).
user1.create_file(params[:file], the_new_folder)
# OR
user1.create_file(File.open('somewhere'), the_new_folder)

# user1 own repository :
#   |-- 'Root folder'
#   |  |-- 'The new folder'
#   |  |   |-- 'file'

# user1 want to create a file on the root of his repository
file2 = user1.create_file(params[:file2])

# user1 own repository :
#   |-- 'Root folder'
#   |  |-- 'The new folder'
#   |  |   |-- 'file'
#   |-- 'file2'

# Delete a repo_item
# Note : user1 needs the ':can_delete => true' permission in the folder : the_new_folder (else the method returns `false`).
user1.delete_repo_item(the_new_folder)

# user1 own repository :
#   |-- 'Root folder'
#   |-- 'file2'

user1.delete_repo_item(file2)

# user1 own repository :
#   |-- 'Root folder'

```

### How can I share a repo_item (file/folder)

Now, user1 want to share his folder 'The new folder' with a Group object `group1` et another User object `user2`. You can use the `has_repository` method `share(repo_item, member, options = nil)`.

```ruby
# user1 wants to share the_new_folder with group1 and user2

members = []
# You can add other instances (who `has_repository`) in this array to share with more than one instance
member << group1
members << user2

sharing = user1.share(the_new_folder, members)

# If you want to customize your sharing options, you can do it like this:
options = {sharing_permissions: {can_add: true, can_remove: true}, repo_item_permissions: {can_read: true, can_create: true, can_update: true, can_delete: true, can_share: true}}

sharing = user1.share(the_new_folder, members, options)
```

`repo_item_permissions` specifies what kind of permissions you give on the repo_item in a specific sharing.

`sharing_permissions` specifies if the member selectionned can add or remove other members in this sharing.

See the chapter [Authorisations](#authorisations) for more details.

### How can I see my repo_items

You can have two kind of repo_items: 
- Your own repo_items
- The repo_items shared with you.

```ruby
# user1 want to get his own repository
user1.repo_items.all # => You get the repo_items that user1 has created

# user2 want to get his shared repo_items
user2.shared_repo_items.all
```

Recall: a repo_item can be:
- A file
- A folder

```ruby
# We want to know if the object repo_item is a file or a folder:
if repo_item.type == 'RepoFolder'
  repo_item.name #=> Returns the name of the folder ('New folder').
elsif repo_item.type == 'RepoFile'
  repo_item.name #=> Returns the name of the file ('file.png').
  # Here is the file
  repo_item.file.url # => '/url/to/file.png'
  repo_item.file.current_path # => 'path/to/file.png'
end
```

For file informations, more infos on [the documentation of the carrierwave gem](https://github.com/carrierwaveuploader/carrierwave). 


### How can I manage a sharing


If it has the authorisation, an object can add members to a sharing.

```ruby
# user1 want to add members to his sharing
# NOTE: The action is done only if user1 has the ':can_add' permission.
user1.can_add_to?(sharing) # => true

# Add members
members = []
members << user3
members << group2
...

user1.add_members_to(sharing, members)

# You can change the default sharing permissions options :
options = {can_add: true, can_remove: false}
user1.add_members_to(sharing, members, options)


# Here user3 and group2 can add members in this sharing, but they can't remove a member.
group2.can_add_to?(sharing) # => true
group2.can_remove_from?(sharing) # => false

# If user2 add a member in the sharing, he can choose if the permission ':can_add' is true or false, but he can't put ':can_remove' to true (because he don't have this permission himself).
```

If an object has the authorisation, it can remove members from a sharing, else the method return `false`.

```ruby
# user1 want to remove group2 from the sharing `sharing`
user1.remove_members_from(sharing, group2) # The second parameter can be an object or an array of object
```

You can directly work with the `sharing`. Be carefull, there is NO authorisation control !

```ruby
# Add a member to the sharing `sharing`
sharing.add_members(member)
# Or with options :
sharing.add_members(member, {can_add: true, can_remove: false})


# Remove members from the sharing
sharing.remove_members({user2, group1})
```

### Authorisations

#### Repository authorisations

The owner of a `repo_item` (file or folder) has all the authorisations on it. When he share this `repo_item`, he can choose what authorisation he gives to the share. The authorisations are :
- can_read?(repo_item) : The member can read (=download) this file/folder.
- can_create?(repo_item) : Can create in the repo_item (Note: if repo_item is nil (= root), always true).
- can_update?(repo_item) : Can update a repo_item.
- can_delete?(repo_item) : Can delete a repo_item.
- can_share?(repo_item) : Can share a repo_item.

To check if a user has one of this authorisation, you just have to write : `user1.can_read?(repo_item)`, `user1.can_share?(repo_item)`, etc (it returns `true` or `false`).

NOTICE : An object who can share a repo_item, can't set new permissions that it doesn't have.
For instance: `user3` has a sharing of `repo_item1` with `:can_delete => false` and `:can_share => true`. He can share `repo_item1` with `user4`, but he can't put `:can_delete => true` in this new share.

You can get all the authorisations with this method: `user1.get_authorisations(repo_item)`

```ruby
      # Gets the repo authorisations
      # Return false if the entity has not the authorisation to share this rep
      # Return true if the entity can share this rep with all the authorisations
      # Return an Array if the entity can share but with restriction
      # Return true if the repo_item is nil (he as all authorisations on his own rep)
      def get_authorisations(repo_item = nil)
        [...]
      end
```

#### Sharing permissions

You can manage the permissions of a member in a sharing. The owner of the sharing has all the permissions. The permissions are:
- can_add_to?(sharing) : The member can add a new instance in this sharing.
- can_remove_from?(sharing) : Can remove an instance from this sharing.

To check if the object can add or remove an instance in the sharing, just write : `group1.can_add_to?(sharing)` or `group1.can_remove_from?(sharing)` (it returns `true` or `false`).

Like the repo_item authorisations, you can get the sharing authorisations with : `group1.get_sharing_authorisations(sharing)`.

## TODO

- Can dowload a file or a folder (auto zip the folder)
- Snapshot the file if possible
- Flexible configuration of authorised extensions
- Versioning
- ...


## License

This project rocks and uses MIT-LICENSE.

