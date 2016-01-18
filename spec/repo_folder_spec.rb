require 'spec_helper'

RSpec.describe RepositoryManager::RepoFolder do
  before do
    @user = FactoryGirl.create(:user)
    @folder = @user.create_folder("parent_folder")
  end

  it "creates a folder by path array" do
    @folder.get_or_create_by_path_array(["subfolder"], owner: @user)
    expect(@user.repo_items.folders.count).to eq(2)
    expect(@user.repo_items.folders.find_by(name: "subfolder").ancestry).to eq(@folder.id.to_s)
  end

  it "gets a folder by path array" do
    path_array = ['1','2','3']
    @folder.get_or_create_by_path_array(path_array.dup, owner: @user)
    @folder.reload
    expect(@user.repo_items.folders.count).to eq(4)

    ancestry_array = path_array.dup.unshift(@folder.name).first(3)
    target = @folder.descendants.find_by(name: '3')

    method_result = @folder.get_by_path_array(path_array)
    expect(method_result.id).to eq(target.id)
    expect(method_result.name).to eq('3')
    expect(method_result.ancestors.pluck(:name)).to eq(ancestry_array)
  end
end
