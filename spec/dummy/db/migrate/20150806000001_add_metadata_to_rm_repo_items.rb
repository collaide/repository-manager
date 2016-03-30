class AddMetadataToRmRepoItems < ActiveRecord::Migration
  def change
    add_column :rm_repo_items, :metadata, :json
  end
end
