require 'spec_helper'

RSpec.describe RepositoryManager::RepoFolder do
  before do
    @user = FactoryBot.create(:user)
    @folder = @user.create_folder("parent_folder")
  end

  it "creates a folder by path array" do
    @folder.get_or_create_by_path_array(["subfolder"], owner: @user)
    expect(@user.repo_items.folders.count).to eq(2)
    expect(@user.repo_items.folders.find_by(name: "subfolder").ancestry).to eq(@folder.id.to_s)
  end
end
