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

## TODO

Gerer les uploads grace à CarrierWare
Implémenter les methodes dans le modèle act_as_repository pour que tout soit plus facile
etc...

## License

This project rocks and uses MIT-LICENSE.

