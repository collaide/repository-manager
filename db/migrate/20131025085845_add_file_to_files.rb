class AddFileToFiles < ActiveRecord::Migration
  def change
    add_column :repositories, :file, :string
  end
end
