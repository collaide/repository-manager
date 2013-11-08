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

  it 'can\'t create a folder in another folder without permission' do
    folder = @user2.createFolder('Folder1', @user1_folder)

    expect(@user1_folder.has_children?).to eq(nil)
    expect(folder).to eq(false)
  end

  it 'can create a file into a folder' do
    file = FactoryGirl.build(:app_file)
    theFile = @user1.createFile(file, @user1_folder)

    expect(@user1_folder.has_children?).to eq(1)
    expect(file).to eq(theFile)
  end

  it 'can\'t create a repo into a file' do
    file = @user2.createFolder('Folder1', @user1_file)

    expect(@user1_file.has_children?).to eq(nil)
    expect(file).to eq(false)
  end

  it 'can delete a file' do
    @user1.deleteRepository(@user1_file)
    expect(@user1.repositories.count).to eq(1)
  end

  it 'can delete a folder an his files' do
    @user1_folder.addRepository(@user1_file)
    @user1.deleteRepository(@user1_folder)
    expect(@user1.repositories.count).to eq(0)
  end

  it 'can\'t delete a repository without permission' do
    @user2.deleteRepository(@user1_file)
    expect(@user1.repositories.count).to eq(2)
  end

  it 'return all the own repositories' do
    expect(@user1.repositories.count()).to eq(2)
  end

  it 'return only the own files' do
    expect(@user1.repositories.files.count()).to eq(1)
  end

  it 'return only the own folders' do
    expect(@user1.repositories.folders.count()).to eq(1)
  end

  it 'can return only the share repositories' do
    #expect(@user2.shares_repositories.count).to eq(0)
    @user1.share(@user1_file, @user2)
    expect(@user2.shares_repositories.count).to eq(1)
  end

  it 'can download a file' do
    #expect(@user2.shares_repositories.count).to eq(0)
    #@user1.download(@user1_file)
    #expect(@user2.shares_repositories.count).to eq(1)
  end

end