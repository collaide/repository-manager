require 'spec_helper'

describe 'Unzip' do

  before do
    @user1 = FactoryBot.create(:user)
    @zip_file = FactoryBot.build(:rm_unzip)
    @zip_file.owner = @user1
    @zip_file.save
  end

  it 'can unzip an archive in root without options' do
    @zip_file.unzip!
    expect(@user1.root_repo_items.count).to eq(3)
    root_folder = @user1.get_item_in_root_by_name('root_folder')
    expect(root_folder.children.count).to eq(4)

    folder_in_root = root_folder.get_children_by_name('Folder In Root')
    expect(folder_in_root.children.count).to eq(3)

    children_folder = folder_in_root.get_children_by_name('Children Folder')
    expect(children_folder.children.count).to eq(2)

    empty_folder = children_folder.get_children_by_name('Empty folder')
    expect(empty_folder.children.count).to eq(0)
  end

  it 'can unzip an archive in a folder and overwrite' do
    root = @user1.create_folder!('The root of the root')

    @zip_file.unzip!(source_folder: root)

    expect(@user1.root_repo_items.count).to eq(2)
    nil_folder = @user1.get_item_in_root_by_name('root_folder')
    expect(nil_folder).to eq(nil)

    root_of_the_root = @user1.get_item_in_root_by_name('The root of the root')
    expect(root_of_the_root).to eq(root)

    root_folder = root_of_the_root.get_children_by_name('root_folder')
    expect(root_folder.children.count).to eq(4)

    folder_in_root = root_folder.get_children_by_name('Folder In Root')
    expect(folder_in_root.children.count).to eq(3)

    children_folder = folder_in_root.get_children_by_name('Children Folder')
    expect(children_folder.children.count).to eq(2)

    empty_folder = children_folder.get_children_by_name('Empty folder')
    expect(empty_folder.children.count).to eq(0)

    @zip_file.unzip!(source_folder: root, overwrite: true) # it raise no error, it works

  end

  it 'User with permission can unzip and other can\'t' do
    @user2 = FactoryBot.create(:user)

    expect(@user1.unzip_repo_item!(@zip_file)).to eq(@zip_file)
    expect(@user2.unzip_repo_item(@zip_file)).to eq(false)
  end

  it 'User can\'t unzip file without create permission' do
    @user2 = FactoryBot.create(:user)
    #shared_folder = @user1.create_folder('Shared Folder')
    @user1.move_repo_item!(@zip_file, source_folder: @user1.create_folder('Shared Folder'))
    @user1.share_repo_item!(@zip_file, @user2, repo_item_permissions: {
        can_read: true,
        can_create: true,
        can_update: true,
        can_delete: false,
        can_share: true
    } )
    # He can t unzip because he don't have the permission to create in shared folder
    expect(@user2.unzip_repo_item(@zip_file)).to eq(false)
  end
end