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
    folder = @user1.create_folder('Folder1', @user1_folder)

    expect(@user1_folder.has_children?).to eq(true)
  end

  it 'can\'t create a folder in another folder without permission' do
    folder = @user2.create_folder('Folder1', @user1_folder)

    expect(@user1_folder.has_children?).to eq(false)
    expect(folder).to eq(false)
  end

  it 'can create a file into a folder' do
    file = FactoryGirl.build(:app_file)
    theFile = @user1.create_file(file, @user1_folder)

    expect(@user1_folder.has_children?).to eq(true)
    expect(file).to eq(theFile)
  end

  it 'can\'t create a repo into a file' do
    file = @user2.create_folder('Folder1', @user1_file)

    expect(@user1_file.has_children?).to eq(false)
    expect(file).to eq(false)
  end

  it 'can delete a file' do
    @user1.delete_repository(@user1_file)
    expect(@user1.repositories.count).to eq(1)
  end

  it 'can delete a folder an his files' do
    @user1_folder.add(@user1_file)
    @user1.delete_repository(@user1_folder)
    expect(@user1.repositories.count).to eq(0)
  end

  it 'can\'t delete a repository without permission' do
    @user2.delete_repository(@user1_file)
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
    #expect(@user2.shared_repositories.count).to eq(0)
    @user1.share(@user1_file, @user2)
    expect(@user2.shared_repositories.count).to eq(1)
  end

  it 'can download a file' do
    #expect(@user2.shared_repositories.count).to eq(0)
    @user1_file.download
    #expect(@user2.shared_repositories.count).to eq(1)
  end

  it 'user can download a file with permission' do
    @user1.download(@user1_file)
    #expect(@user2.shared_repositories.count).to eq(1)
  end

  it 'user can\'t download a file without permission' do
    path = @user2.download(@user1_file)
    expect(path).to eq(false)
  end

  #it 'download the file if there is just one in a folder (no zip)' do
  #  @user1_folder.add(@user1_file)
  #  @user1.download(@user1_folder)
  #end

  it 'user can download a folder with nested folder (zip)' do
    folder = @user1.create_folder('Folder1', @user1_folder)
    folder2 = @user1.create_folder('Folder2', folder)
    @user1.create_file(@user1_file, folder)

    user1_file2 = FactoryGirl.build(:app_file)
    user1_file2.owner = @user1
    user1_file2.save
    @user1.create_file(user1_file2, folder2)

    user1_file3 = FactoryGirl.build(:app_file)
    user1_file3.owner = @user1
    user1_file3.save
    @user1.create_file(user1_file3, @user1_folder)


    pp @user1.download(@user1_folder)
  end

  it 'can\'t add a repository with the same name in a folder' do
    folder = @user1.create_folder('Folder1', @user1_folder)
    expect(@user1.repositories.count).to eq(3)
    folder2 = @user1.create_folder('Folder1', @user1_folder)
    expect(folder2).to eq(false)
    expect(@user1.repositories.count).to eq(3)
    folder3 = @user1.create_folder('Folder2', @user1_folder)
    expect(@user1.repositories.count).to eq(4)
  end

end