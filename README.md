Ruby on Rails plugin (gem) for managing repositories (files/folders/permissions). 

# RepositoryManager

This project is based on the need for a repository manager system for [Collaide](https://github.com/facenord-sud/collaide). Instead of creating my core repository manager system heavily
dependent on our development, I'm trying to implement a generic and potent repository gem.

After looking for a good gem to use I noticed the lack of repository gems
and flexibility in them. RepositoryManager tries to be the more flexible possible.
Each instance (users, groups, etc..) can have it own repositories (with files and folders). It can manage them easily (edit, remove, add, etc) and share them with other instance.

This gem is my informatic project for the Master in [University of Lausanne (CH)](http://www.unil.ch/index.html). 

WARNING : This gem is not finish, only a few method are implemented !

## Installation

TODO : This is not mad !!!


Add to your Gemfile:

```ruby
gem 'RepositoryManager'
```

Then run:

```sh
$ bundle update
```

Run install script:

```sh
$ rails g RepositoryManager:install
```

And don't forget to migrate your database:

```sh
$ rake db:migrate
```

## Preparing your models

You can choose wich model can have repository. 

In your model:

```ruby
class User < ActiveRecord::Base
  has_repository
end
```

You are not limited to the User model. You can use RepositoryManager in any other model and use it in serveral different models. If you have Groups and Houses in your application and you want to exchange repositories as if they were the same, just add `has_repository` to each one and you will be able to share files/folders groups-groups, groups-users, users-groups and users-users. Of course, you can extend it for as many classes as you need.

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

### How can I create a file/folder

You just have to call the method createFile, or createFolder.

```ruby
# user1 wants to create a folder in a directory (he needs to have the ':can_create' permission in this directory !)

# sourceFolder is the directory in wich user1 wants to create the folder
sourceFolder = createFolder('Root folder')

name = 'The new folder'
theFolder = user1.createFolder(name, sourceFolder)

# Now we want to add a file into theFolder (user1 needs the ':can_create' permission in the folder : theFolder)
user1.createFile(params[:file], theFolder)
# OR
user1.createFile(File.open('somewhere'), theFolder)

```

### How can I share a repository (file/folder)

Now, user1 want to share his 'The new folder' with a Group object et another User.

```ruby
# user1 wants to share theFolder with group1 and user2

items = []
# You can add other instance (who acts_as_repository) in this array to share with more than one instance
item << group1
items << user2

# Default shares permisions are : {can_add: false, can_remove: false} 
share_permissions = {can_add: true, can_remove: true}
# Default reposiroty permissions are: {can_read: false, can_create: false, can_update:false, can_delete:false, can_share: false}
repo_permissions = {can_read: true, can_create: true, can_update:true, can_delete:true, can_share: true}

share = user1.share(theFolder, items, repo_permissions, share_permissions)
```

`share_permissions` specifies if the item who receive the share can add or remove items in this share.
`repo_permissions` specifies what kind of permission do you give at this share. If all the params are false (as_default), the share is useless, because the items have no more permissions in the repository selectionned. 

See the chapter Authorisations for more details.

### How can I see my repository

There is two king of repository: 
- Your own repositories
- The repositories shared with you.

```ruby
# user1 want to get his own repository
user1.repositories.all # => You get the repository that user1 has created

# user2 want to get his shared repository
user2.shares_repositories.all
```

### How can I manage a share


If it has the authorisation, an object can add items to a share.
```ruby
#user1 want to add items to his share (the actions are done only if user1 has the ':can_add' permission)
user1.can_add_to_share(share) # => true

share_permissions = {can_add: true, can_remove: false}
#Add items
items = []
items << user3
items << group2
...
@user1.addItemsToShare(share, items, share_permissions)

# Here user3 and group2 can add items in this share, but they can't remove an item.
group2.can_add_to_share(share) # => true
group2.can_remove_to_share(share) # => false

# If user2 add an item in the share, he can choose if the permission ':can_add' is true or false, but he can't put ':can_remove' to true (because he don't have this permission himself).
```

If it has the authorisation, an object can remove items to a share.
```ruby
# user1 want to remove group2 from this share
user1.removeItemsToShare(share, group2)
```

As admin, you can directly work with the share. Be carefull, there is NO authorisation verification !
```ruby
# Add an item to the share
share.addItems(item, share_permissions)

# Delete items from the share
share.removeItems(items)
```

### Authorisations

#### Repository authorisations

The owner of a repository (file or folder) has all the authorisations on it. When he share this repository, he can choose what authorisation he gives to the share. The authorisations are :
- can_read(repository) : The item can read (=download) this file/folder.
- can_create(repository) : Can create in the repository (if repository is nil (= root), always true).
- can_update(repository) : Can update a repository.
- can_delete(repository) : Can delete a repository.
- can_share(repository) : Can share a repository.

To check if a user has one of this authorisation, you just have to write : `user1.can_read(repository)`, `user1.can_share(repository)`, etc (it returns `true` or `false`).

NOTICE : An object who can share a repository, can't set new permissions that it doesn't have. 
For instance, `user3` has a share of `repository1` with `:can_delete => false` and `:can_share => true`. He can share `repository1` with `user4`, but he can't put `:can_delete => true` in this new share.

You can get all the authorisations with this method: `user1.get_authorisations(repository)`
```ruby
# Returns false if the object has no authorisation in this repository
# Returns true if the object has all the authorisations
# Returns a Hash if the entity has custums authorisations 
#   Exemple
#     {can_read: true, can_create: true, can_update:true, can_delete:false, can_share: true}
# Returns true if the repository is nil (because an object has all authorisations on his root folder)
def get_authorisations(repository=nil)
    [...]
end
```

#### Share permissions

You can manage the permission of an instance in a share. The owner of the share has all the permissions. The permissions are:
- can_add_to_share(share) : The item can add a new instance in this share.
- can_remove_to_share(share) : Can remove an instance from this share.

To check if the object can add or remove an instance in the share, just write : `group1.can_add_to_share(share)` or `group1.can_remove_to_share(share)` (it returns `true` or `false`).

Like the repository authorisations, you can get the share authorisations with : `group1.get_share_authorisations(share)`.

## License

This project rocks and uses MIT-LICENSE.

