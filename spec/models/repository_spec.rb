require 'spec_helper'

describe 'RepoItem' do

  before do
    @user1 = FactoryBot.create(:user)
    @user2 = FactoryBot.create(:user)
    @user1_file = FactoryBot.build(:rm_repo_file)
    @user1_file.owner = @user1
    @user1_file.save
    @user1_folder = FactoryBot.build(:rm_repo_folder)
    @user1_folder.owner = @user1
    @user1_folder.save
    @user1_file.save
  end

  it 'can create a folder in it own folder' do
    @user1.create_folder('Folder1', source_folder: @user1_folder)

    expect(@user1_folder.has_children?).to eq(true)
  end

  it 'can\'t create a folder in it a file' do
    options = {source_folder: @user1_file}
    folder = @user1.create_folder('Folder1', options)

    expect(options[:errors]).to eq(['The folder was not created'])

    expect(folder).to eq(false)
  end

  it 'file has md5' do
    expect(@user1_file.checksum).to eq(Digest::MD5.file(File.open("#{Rails.root}/../fixture/textfile.txt")).hexdigest)
  end

  it 'can\'t create a folder in another folder without permission' do
    options = {source_folder: @user1_folder}
    folder = @user2.create_folder('Folder1', options)

    expect(options[:errors]).to eq(['You don\'t have the permission to create a folder'])

    expect(@user1_folder.has_children?).to eq(false)
    expect(folder).to eq(false)
  end

  it 'can create a file into a folder' do
    file = FactoryBot.build(:rm_repo_file)
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
    expect(@user1.reload.repo_items.count).to eq(0)
  end

  it 'can\'t delete a repo_item without permission' do
    @user2.delete_repo_item(@user1_file)
    expect(@user1_file.errors.messages).to eq({delete: ['You don\'t have the permission to delete this item']})

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
    @user1.share_repo_item(@user1_file, @user2)
    expect(@user2.shared_repo_items.count).to eq(1)
  end

  it 'can download a file' do
    #expect(@user2.shared_repo_items.count).to eq(0)
    @user1_file.download
    #expect(@user2.shared_repo_items.count).to eq(1)
  end

  it 'user can download a file with permission' do
    @user1.download_repo_item(@user1_file)
    #expect(@user2.shared_repo_items.count).to eq(1)
  end

  it 'user can\'t download a file without permission' do
    path = @user2.download_repo_item(@user1_file)
    expect(path).to eq(false)
    expect(@user1_file.errors.messages).to eq({download: ['You don\'t have the permission to download this item']})

  end

  #it 'download the file if there is just one in a folder (no zip)' do
  #  @user1_folder.add(@user1_file)
  #  @user1.download(@user1_folder)
  #end

  it 'user can download a folder with nested folder (zip)' do
    folder = @user1.create_folder('Folder1', source_folder: @user1_folder)
    folder2 = @user1.create_folder('Folder2', source_folder: folder)
    @user1.create_file(@user1_file, source_folder: folder)

    user1_file2 = FactoryBot.build(:rm_repo_file)
    user1_file2.owner = @user1
    user1_file2.save
    @user1.create_file(user1_file2, source_folder: folder2)

    user1_file3 = FactoryBot.build(:rm_repo_file)
    user1_file3.owner = @user1
    user1_file3.save
    @user1.create_file(user1_file3, source_folder: @user1_folder)

    @user1.download_repo_item(@user1_folder)
    @user1.download_repo_item(@user1_folder)
    @user1_folder.download

    @user1_folder.delete_zip
    @user1.delete_download_path()
  end

  it 'can download a hard folder (nested folders and files)' do
    nested = @user2.create_folder!('a')
    a = @user2.create_folder!('a', source_folder: nested)
    b = @user2.create_folder!('b', source_folder: a)
    c = @user2.create_folder!('c', source_folder: b)
    d = @user2.create_folder!('a', source_folder: c)
    e = @user2.create_folder!('a', source_folder: d)

    file = FactoryBot.build(:rm_repo_file)
    #@user2.create_file!(file, source_folder: a)
    #@user2.create_file!(file, source_folder: nested)
    @user2.create_file!(file, source_folder: c)
    @user2.download_repo_item(nested)
    @user2.delete_download_path()
  end

  it 'can copy a hard folder (nested folders and files)' do
    nested = @user2.create_folder!('a')
    a = @user2.create_folder!('a', source_folder: nested)
    b = @user2.create_folder!('b', source_folder: a)
    c = @user2.create_folder!('c', source_folder: b)
    d = @user2.create_folder!('a', source_folder: c)
    e = @user2.create_folder!('a', source_folder: d)

    file = FactoryBot.build(:rm_repo_file)
    #@user2.create_file!(file, source_folder: a)
    #@user2.create_file!(file, source_folder: nested)
    @user2.create_file!(file, source_folder: c)
    @user2.share_repo_item!(nested, @user1, repo_item_permissions: {can_read: true})
    copy = @user1.copy_repo_item!(nested)
    @user1.download_repo_item(copy)
    @user1.delete_download_path()
  end

  it 'can\'t copy directly a file in same ort' do
    expect(@user1_file.copy).to eq(false)
  end

  it 'can copy directly a file' do
    @user1_file.copy!(source_folder: @user1_folder)
  end

  it 'can\'t add a repo_item with the same name in a folder' do
    root_folder = @user1.create_folder('Root folder')
    root_folder.add(@user1_folder)

    root_test_folder = @user1.create_folder('root test folder')
    test_folder = @user1.create_folder('Test folder', source_folder: root_test_folder)
    @user1.create_folder('Nested test folder', source_folder: test_folder)

    @user1.move_repo_item(test_folder, source_folder: @user1_folder)

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
    expect(@user1_folder.errors.messages).to eq({rename: ['You don\'t have the permission to rename this item']})

    expect(@user1_folder.reload.name).to eq('Folder')
  end

  it 'can create a new folder with different name' do
    folder1 = @user1.create_folder()
    folder3 = @user1.create_folder('', source_folder: folder1)
    folder4 = @user1.create_folder('', source_folder: folder1)
    folder2 = @user1.create_folder()
    folder5 = @user1.create_folder()
    folder6 = @user1.create_folder('', source_folder: folder1)

    expect(folder1.name).to eq('New folder')
    expect(folder2.name).to eq('New folder 2')
    expect(folder3.name).to eq('New folder')
    expect(folder4.name).to eq('New folder 2')
    expect(folder5.name).to eq('New folder 3')
    expect(folder6.name).to eq('New folder 3')
  end

  it 'can\'t create a folder with the same name at root' do
    @user1.create_folder('test')
    folder2 = @user1.create_folder('test',options={})

    expect(options[:errors]).to eq(['This folder already exist'])

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
    options = {source_folder: @user1_folder}
    file2 = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), options)
    expect(file2).to eq(false)
    expect(options[:errors]).to eq(['This file already exist'])
  end

  it "can rename a file" do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)
    @user1.rename_repo_item(file, 'lol.txt')
    expect(file.reload.name).to eq('lol.txt')
    @user1.create_file!(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)
    file2 = @user1.create_file!(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder, filename: 'haha.txt')

    expect(file2.reload.name).to eq('haha.txt')
    expect(@user1_folder.children.count).to eq(3)
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

    @user2.move_repo_item!(file, source_folder: folder)

    expect(folder.children).to eq([file])
  end

  it "can move a folder into a folder" do
    folder = @user2.create_folder('folder')
    folder2 = @user2.create_folder('folder2')
    @user2.move_repo_item!(folder, source_folder: folder2)

    expect(folder2.children).to eq([folder])
  end

  it "can't move a folder into a file" do
    file = @user2.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"))
    folder = @user2.create_folder('folder')

    expect(@user2.move_repo_item(folder, source_folder: file)).to eq(false)
    expect(folder.errors.messages).to eq({move: ['This item was not moved']})
  end

  it "move_repo_item default to the root of the self owner" do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)

    @user1.delete_repo_item!(@user1_file)
    #expect(@user1.root_repo_items.count).to eq(1)
    @user1.move_repo_item!(file)
    expect(@user1.root_repo_items.count).to eq(2)
  end

  it "move_repo_item can't move a file into a root if file already exist" do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)
    expect(@user1.move_repo_item(file)).to eq(false)
    expect(file.errors.messages).to eq({move: ['This item already exist in the target destination']})

  end

  it "move_repo_item can't move if no permission" do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)
    expect(@user2.move_repo_item(file)).to eq(false)
    expect(file.errors.messages).to eq({move: ['You don\'t have the permission to move this item']})
  end

  it "can move an item with the same name and overwrite it" do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)
    expect(@user1.move_repo_item!(file, overwrite: true)).to eq(@user1_file)
    overwrited = RepositoryManager::RepoItem.where(id: file.id).first
    expect(overwrited).to eq(nil)
  end

  it "can copy an item with the same name and overwrite it" do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)
    copied_file = @user1.copy_repo_item!(file, overwrite: true)
    expect(@user1_file).to eq(copied_file)
  end


  it "can copy an item with the same name in folder and overwrite it" do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder)
    copied_file = @user1.copy_repo_item!(@user1_file, source_folder: @user1_folder, overwrite: true)
    expect(copied_file).to eq(file)
  end

  it 'can create a folder with same name and overwrite the old one' do
    folder = @user1.create_folder('Folder', overwrite: true)

    overwrited = RepositoryManager::RepoItem.where(id: @user1_folder.id).first
    expect(overwrited).to eq(nil)
    expect(folder.name).to eq("Folder")
  end

  it 'can create a file with same name and update the old one' do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"), overwrite: true)

    overwrited = RepositoryManager::RepoItem.where(id: @user1_file.id).first
    expect(overwrited).to eq(file)
  end

  it 'can create a file in folder with same name and update the old one' do
    @user1.move_repo_item(@user1_file, source_folder: @user1_folder)
    file = @user1.create_file!(File.open("#{Rails.root}/../fixture/textfile.txt"), source_folder: @user1_folder, overwrite: true)
    overwrited = RepositoryManager::RepoItem.where(id: @user1_file.id).first
    expect(overwrited).to eq(file)
    #expect(folder.name).to eq("Folder")
  end

  it "can't copy a file without permission" do
    expect(@user2.copy_repo_item(@user1_file)).to eq(false)
    expect(@user1_file.errors.messages).to eq({copy: ['You don\'t have the permission to copy this item']})
  end
  
  it "can copy a file with read permission" do
    @user1.share_repo_item(@user1_file, @user2, repo_item_permissions: {can_read:true})
    @user2.copy_repo_item(@user1_file)
    expect(@user2.root_repo_items.count).to eq(1)
  end

  it "can copy a file with read permission in a folder" do
    @user1.share_repo_item(@user1_file, @user2, repo_item_permissions: {can_read:true})
    fold = @user2.create_folder!('fold')
    @user2.copy_repo_item!(@user1_file, source_folder: fold)
    expect(fold.children.count).to eq(1)
  end
end
