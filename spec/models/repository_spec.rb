require 'spec_helper'

describe 'Repository' do

  before do
    @user1 = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)
    @user1_file = FactoryGirl.build(:app_file)
    @user1_file.owner = @user1
    @user1_folder = FactoryGirl.build(:folder)
    @user1_folder.owner = @user1
    @user1_folder.save
    @user1_file.save
  end

  it 'can create a folder in it own folder' do
    folder = @user1.createFolder('Folder1', @user1_folder)

    expect(@user1_folder.has_children?).to eq(1)
  end
end