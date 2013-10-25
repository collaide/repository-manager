class AddFileToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :repository, :string
    add_column :repositories, :file_size, :float
    add_column :repositories, :content_type, :string
  end
end
