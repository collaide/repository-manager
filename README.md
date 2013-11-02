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

```ruby
#user1 wants to share a file or folder with user2

items = []
#You can add other instance (who acts_as_repository) in this array to share with more than one instance
items << user2

#Share permission can specifie if the instance who receive the share can add or remove user in this share (if he is admin of this share, for instance).
#Default shares permisions are : 
share_permissions = {can_add: false, can_remove: false}

The repository permission spicifie what kind of permission do you give at this share. If all in false (as default), this is like the share doesn't exist, becose you can't se the files/folders end can't edit or remove it.
So, you have to be carefull of being consis in you choice of permissions. For exemple, is there a sence to put can_read to false et can_update to true ?
But this parametre permit you to do what ever you want.
The can_share option is the fact that the user can share this repository too or not.
#Default reposiroty permissions are:
repo_permissions = {can_read: false, can_create: false, can_update:false, can_delete:false, can_share: false}

user1.share(repository, items, repo_permissions, share_permissions)
```

## TODO

Gerer les uploads grace à CarrierWare
Implémenter les methodes dans le modèle act_as_repository pour que tout soit plus facile
etc...

## License

This project rocks and uses MIT-LICENSE.

