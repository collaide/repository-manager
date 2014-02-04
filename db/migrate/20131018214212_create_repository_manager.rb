class CreateRepositoryManager < ActiveRecord::Migration

  def change

    create_table :sharings do |t|
      t.references :owner, polymorphic: true, index: true
      t.references :user, index: true
      t.references :repo_item, index: true
      t.boolean :can_create, :default => false
      t.boolean :can_read, :default => false
      t.boolean :can_update, :default => false
      t.boolean :can_delete, :default => false
      t.boolean :can_share, :default => false
    end

    create_table :sharings_members do |t|
      t.references :sharing
      t.references :member, polymorphic: true
      t.boolean :can_add, :default => false
      t.boolean :can_remove, :default => false
    end

    create_table :repo_items do |t|
      t.references :owner, polymorphic: true, index: true
      t.references :user, index: true
      t.string :ancestry
      #t.integer :ancestry_depth, :default => 0
      t.string :name
      t.float :file_size
      t.string :content_type
      t.string :file
      t.string :type
    end
  end
end