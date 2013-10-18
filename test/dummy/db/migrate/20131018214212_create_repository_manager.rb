class CreateRepositoryManager < ActiveRecord::Migration

  def change
    create_table :permissions do |t|
      t.boolean :can_create, :default => false
      t.boolean :can_read, :default => false
      t.boolean :can_update, :default => false
      t.boolean :can_delete, :default => false
      t.boolean :can_share, :default => false
    end

    create_table :shares do |t|
      t.integer :permission_id
      #t.integer :user_id
      t.references :owner, polymorphic: true
      t.integer :app_file_id
    end

    create_table :shares_items do |t|
      t.integer :share_id
      #t.integer :item_type
      #t.integer :item_id
      t.references :shareable, polymorphic: true
      t.boolean :can_add, :default => false
      t.boolean :can_remove, :default => false
    end

    create_table :app_files do |t|
      t.references :owner, polymorphic: true
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt
      t.integer :depth # this is optional.
    end

  end
end