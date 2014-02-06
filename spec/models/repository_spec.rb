require 'spec_helper'

describe 'RepoItem' do

  before do
    @user1 = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)
    @user1_file = FactoryGirl.build(:rm_repo_file)
    @user1_file.owner = @user1
    @user1_file.save
    @user1_folder = FactoryGirl.build(:rm_repo_folder)
    @user1_folder.owner = @user1
    @user1_folder.save
    @user1_file.save
  end

  it 'can create a folder in it own folder' do
    @user1.create_folder('Folder1', source_folder: @user1_folder)

    expect(@user1_folder.has_children?).to eq(true)
  end

  it 'can\'t create a folder in it a file' do
    folder = @user1.create_folder('Folder1', source_folder: @user1_file)

    expect(folder).to eq(false)
  end


  it 'can\'t create a folder in another folder without permission' do
    folder = @user2.create_folder('Folder1', source_folder: @user1_folder)

    expect(@user1_folder.has_children?).to eq(false)
    expect(folder).to eq(false)
  end

  it 'can create a file into a folder' do
    file = FactoryGirl.build(:rm_repo_file)
    theFile = @user1.create_file(file, source_folder: @user1_folder)

    expect(@user1_folder.has_children?).to eq(true)
    expect(file).to eq(theFile)
  end

  it 'can\'t create a repo into a file' do
    file = @user2.create_folder('Folder1', source_folder: @user1_file)

    expect(@user1_file.has_children?).to eq(false)
    expect(file).to eq(false)
  end

  it 'can delete a file' do
    @user1.delete_repo_item(@user1_file)
    expect(@user1.repo_items.count).to eq(1)
  end

  it 'can delete a folder an his files' do
    @user1_folder.add(@user1_file)
    @user1.delete_repo_item(@user1_folder)
    expect(@user1.repo_items.count).to eq(0)
  end

  it 'can\'t delete a repo_item without permission' do
    @user2.delete_repo_item(@user1_file)
    expect(@user1.repo_items.count).to eq(2)
  end

  it 'return all the own repo_items' do
    expect(@user1.repo_items.count()).to eq(2)
  end

  it 'return only the own files' do
    expect(@user1.repo_items.files.count()).to eq(1)
  end

  it 'return only the own folders' do
    expect(@user1.repo_items.folders.count()).to eq(1)
  end

  it 'can return only the sharing repo_items' do
    #expect(@user2.shared_repo_items.count).to eq(0)
    @user1.share(@user1_file, @user2)
    expect(@user2.shared_repo_items.count).to eq(1)
  end

  it 'can download a file' do
    #expect(@user2.shared_repo_items.count).to eq(0)
    @user1_file.download
    #expect(@user2.shared_repo_items.count).to eq(1)
  end

  it 'user can download a file with permission' do
    @user1.download(@user1_file)
    #expect(@user2.shared_repo_items.count).to eq(1)
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
    folder = @user1.create_folder('Folder1', source_folder: @user1_folder)
    folder2 = @user1.create_folder('Folder2', source_folder: folder)
    @user1.create_file(@user1_file, source_folder: folder)

    user1_file2 = FactoryGirl.build(:rm_repo_file)
    user1_file2.owner = @user1
    user1_file2.save
    @user1.create_file(user1_file2, source_folder: folder2)

    user1_file3 = FactoryGirl.build(:rm_repo_file)
    user1_file3.owner = @user1
    user1_file3.save
    @user1.create_file(user1_file3, source_folder: @user1_folder)

    @user1.download(@user1_folder)
    @user1.download(@user1_folder)
    @user1_folder.download

    @user1_folder.delete_zip
    @user1.delete_download_path()
  end

  it 'can\'t add a repo_item with the same name in a folder' do
    root_folder = @user1.create_folder('Root folder')
    root_folder.add(@user1_folder)

    root_test_folder = @user1.create_folder('root test folder')
    test_folder = @user1.create_folder('Test folder', source_folder: root_test_folder)
    @user1.create_folder('Nested test folder', source_folder: test_folder)

    @user1.move_repo_item(test_folder, @user1_folder)

    expect(test_folder.parent_id).to eq(@user1_folder.id)
  end

  it 'can rename it own folder' do
    @user1.rename_repo_item(@user1_folder, 'test new name')

    expect(@user1_folder.reload.name).to eq('test new name')

  end

  it 'can rename it own file' do
    #Todo implement
  end

  it 'can rename item with share update permission' do
    # TODO
  end

  it 'can\'t rename item without share update permission' do
    @user2.rename_repo_item(@user1_folder, 'test new name')
    expect(@user1_folder.reload.name).to eq('Folder')
  end

  it 'can create a new folder with different name' do
    folder1 = @user1.create_folder()
    folder3 = @user1.create_folder('', source_folder: folder1)
    folder4 = @user1.create_folder('', source_folder: folder1)
    folder2 = @user1.create_folder()

    # TODO add translate in gem
    expect(folder1.name).to eq('translation missing: en.repository_manager.models.repo_folder.name')
    expect(folder2.name).to eq('translation missing: en.repository_manager.models.repo_folder.name 2')
    expect(folder3.name).to eq('translation missing: en.repository_manager.models.repo_folder.name')
    expect(folder4.name).to eq('translation missing: en.repository_manager.models.repo_folder.name 2')

  end

  it 'can\'t create a folder with the same name at root' do
    @user1.create_folder('test')
    folder2 = @user1.create_folder('test')

    expect(folder2).to eq(false)
  end

  it "can't create too file with the same name at root" do
    file = @user2.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"))
    expect(file.name).to eq('textfile.txt')
    file2 = @user2.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"))
    expect(file2).to eq(false)

    #@user1.create_file!(File.open("#{Rails.root}/../fixture/textfile.txt"))
  end

  it "can't create too file with the same name in folder" do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)
    expect(file.name).to eq('textfile.txt')
    file2 = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)
    expect(file2).to eq(false)

    #@user1.create_file!(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)
  end

  it 'sender is equal to owner if no sender in create_folder' do
    folder = @user1.create_folder('test')
    expect(folder.sender).to eq(@user1)
  end

  it 'sender is equal to owner if no sender in create_file' do
    file = @user2.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"))
    expect(file.sender).to eq(@user2)
  end

  it 'can specify a sender in create_folder method' do
    folder = @user1.create_folder('test', sender: @user2)
    expect(folder.sender).to eq(@user2)
  end

  it 'can specify a sender in create_file method' do
    file = @user2.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), sender: @user1)
    expect(file.sender).to eq(@user1)
  end

  it "can move a file to folder" do
    file = @user2.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"))
    folder = @user2.create_folder('folder')

    @user2.move_repo_item(file, folder)

    expect(folder.children).to eq([file])
  end

  it "can move a folder to folder" do
    folder = @user2.create_folder('folder')
    folder2 = @user2.create_folder('folder2')
    @user2.move_repo_item(folder, folder2)

    expect(folder2.children).to eq([folder])
  end

  it "can't move a folder into a file" do
    file = @user2.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"))
    folder = @user2.create_folder('folder')

    expect(@user2.move_repo_item(folder,file)).to eq(false)
  end

end