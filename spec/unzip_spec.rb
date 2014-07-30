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

end