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

## Requirements & Settings

TODO

## Preparing your models

In your model:

```ruby
class User < ActiveRecord::Base
  acts_as_repository
end
```

You are not limited to the User model. You can use RepositoryManager in any other model and use it in serveral different models. If you have groups and Houses in your application and you want to exchange repositories as if they were the same, just add `acts_as_repository` to each one and you will be able to share files/folders groups-groups, groups-users, users-groups and users-users. Of course, you can extend it for as many classes as you need.

Example:

```ruby
class User < ActiveRecord::Base
  acts_as_repository
end
```

```ruby
class Group < ActiveRecord::Base
  acts_as_repository
end
```

## How to use RepositoryManager

### How can I share a file/folder

Read the comments in the code below.

```ruby
#user1 wants to share a file or folder with user2

items = []
#You can add other instance (who acts_as_repository) in this array to share with more than one instance
items << user2

#Share permission can specifie if the instance who receive the share can add or remove user in this share (if he is admin of this share, for instance).
#Default shares permisions are : 
share_permissions = {can_add: false, can_remove: false}

#The repository permission spicifie what kind of permission do you give at this share. If all in false (as default), this is like the share doesn't exist, becose you can't se the files/folders end can't edit or remove it.
#So, you have to be carefull of being consis in you choice of permissions. For exemple, is there a sence to put can_read to false et can_update to true ?
#But this parametre permit you to do what ever you want.

#The can_share option is the fact that the user can share this repository too or not.

#NOTICE : An instance who can share a repository, can't set permissions that it doesn't have. For instance, if user1 has a share of rep1. In this share option, he has can_delete => false. In this case, he can't create a share with can_delete => true.

#Default reposiroty permissions are:
repo_permissions = {can_read: false, can_create: false, can_update:false, can_delete:false, can_share: false}

user1.share(repository, items, repo_permissions, share_permissions)
```

### How can I create a file/folder

You just have to call the method createFile, or createFolder.

```ruby
#user1 wants to create a folder in another directory (he needs the create permission !)

#sourceFolder is the directory in wich you want to create the folder
sourceFolder = user1_folder

#The name of the new folder
name = 'Folder1'
folder = @user1.createFolder('Folder1', @user1_folder)

#Ok, now we want to add a file into this folder (he needs the create permission)
file = AppFile.new
file.name = params[:file]
#OR
file.name = File.open('somewhere')

#Add this file in the folder named 'Folder1'
@user1.createFile(file, folder)
#OR more easy :
@user1.createFile(params[:file], folder)
```

### Authorisations

The owner of a repository (file or folder) has all the authorisations on it. The authorisations are :
- can_create(repository) : You can create a file/folder on the repository (if repository is nil, you can create).
- can_edit(repository) : You can edit a file/folder
- can_delete(repository) : You can delete a repository
- can_share(repository) : You can share a repository

This method returns true if you can do the action, else false. All these methods are user get_authorisations method:
```ruby
#Return false if the entity has not the authorisation to share this rep
#Return true if the entity can share this rep with all the authorisations
#eturn an Array if the entity can share but with restriction
#Return true if the repository is nil (he as all authorisations on his own rep)
def get_authorisations(repository=nil)
```

## TODO

Verifier les droits, quand on crée un dossier
Gerer les uploads grace à CarrierWare
Implémenter les methodes dans le modèle act_as_repository pour que tout soit plus facile
etc...

## License

This project rocks and uses MIT-LICENSE.

