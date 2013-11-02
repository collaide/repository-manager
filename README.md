Ruby on Rails plugin (gem) for managing repositories (files/folders/permissions). 

= RepositoryManager

This project is based on the need for a repository manager system for [Collaide](https://github.com/facenord-sud/collaide). Instead of creating my core repository manager system heavily
dependent on our development, I'm trying to implement a generic and potent repository gem.

After looking for a good gem to use I noticed the lack of repository gems
and flexibility in them. RepositoryManager tries to be the more flexible possible.
Each instance (users, groups, etc..) can have it own repositories (with files and folders). It can manage them easily (edit, remove, add, etc) and share them with other instance.

This gem is my informatic project for the Master in University of Lausanne (CH). 

WARNING : This gem is not finish, only a few method are implemented !

== Installation

Installation
------------

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


== TODO

Gerer les uploads grace à CarrierWare
Implémenter les methodes dans le modèle act_as_repository pour que tout soit plus facile
etc...

== License

This project rocks and uses MIT-LICENSE.

