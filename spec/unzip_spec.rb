require 'spec_helper'

describe 'Unzip' do

  before do
    @user1 = FactoryGirl.create(:user)
    @zip_file = FactoryGirl.build(:rm_unzip)
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
    @user2 = FactoryGirl.create(:user)

    expect(@user1.unzip_repo_item!(@zip_file)).to eq(@zip_file)
    expect(@user2.unzip_repo_item(@zip_file)).to eq(false)
  end

  # TODO test change owner and sender

end