require 'spec_helper'

describe 'HasRepository' do

  before do
    @user1 = FactoryBot.create(:user)
    @user2 = FactoryBot.create(:user)
    @user3 = FactoryBot.create(:user)
    @user4 = FactoryBot.create(:user)
    @folder = @user4.create_folder("parent_folder")
    @group1 = FactoryBot.create(:group)
  end

  it "creates a folder by path array" do
    @user4.get_or_create_by_path_array([@folder.name, "subfolder"])
    expect(@user4.repo_items.folders.count).to eq(2)
    expect(@user4.repo_items.folders.find_by(name: "subfolder").ancestry).to eq(@folder.id.to_s)
  end

  it "should be associate with shares" do
    folder = @user1.create_folder('salut')
    sharing = RepositoryManager::Sharing.new
    sharing.repo_item = folder
    sharing.save
    @user2.sharings << sharing
    expect(@user2.sharings.last).to eq(sharing)
  end

  it 'can share his own repo_item with other users' do
    rep = FactoryBot.build(:rm_repo_file)
    rep.owner = @user1
    rep.save

    #expect(@user1.sharings.count).to eq(0)
    #expect(@user2.sharings.count).to eq(0)
    #expect(@user3.sharings.count).to eq(0)
    #expect(@user1.sharings_owners.count).to eq(0)
    #expect(@user2.sharings_owners.count).to eq(0)
    #expect(@user3.sharings_owners.count).to eq(0)

    #Add the 2 users to members
    members = []
    members << @user2
    members << @user3

    @user1.share_repo_item(rep, members)

    #expect(@user1.sharings.count).to eq(0)
    expect(@user2.sharings.count).to eq(1)
    expect(@user3.sharings.count).to eq(1)
    expect(@user1.sharings_owners.count).to eq(1)
    expect(@user2.repo_items.count).to eq(0)
    #expect(@user2.sharingd_repo_items.count).to eq(1)

    #expect(@user2.sharings_owners.count).to eq(0)
    #expect(@user3.sharings_owners.count).to eq(0)

  end

  it 'can not share a repo_item without sharings and without the permission' do
    rep = FactoryBot.build(:rm_repo_file)
    rep.owner = @user3
    rep.save

    members = []
    members << @user2

    @user1.share_repo_item(rep, members)

    expect(rep.errors.messages).to eq({sharing: ['You don\'t have the permission to share this item']})

    expect(@user2.sharings.count).to eq(0)
    expect(@user1.sharings_owners.count).to eq(0)
  end

  it 'can not share a repo_item with sharing but without the permission' do
    rep = FactoryBot.build(:rm_repo_folder)
    rep.owner = @user3
    rep.save

    members = []
    members << @user2

    # here user3 can share because he is the owner
    @user3.share_repo_item(rep, members)
    # here user2 should can share because he has the permission
    members = []
    members << @user1
    @user2.share_repo_item(rep, members)

    expect(@user1.sharings.count).to eq(0)
    expect(@user2.sharings_owners.count).to eq(0)
  end

  it 'can share a repo_item with sharing and with the permission' do
    rep = FactoryBot.build(:rm_repo_folder)
    rep.owner = @user3
    rep.save

    members = []
    members << @user2

    #Here user3 let user2 share this repo too
    options = {repo_item_permissions: {can_share: true}}

    # here user3 can share because he is the owner
    @user3.share_repo_item(rep, members, options)
    # here user2 should can share because he has the permission
    members = []
    members << @user1
    @user2.share_repo_item(rep, members)

    expect(@user1.sharings.count).to eq(1)
    expect(@user2.sharings_owners.count).to eq(1)
  end

  it 'default sharings permissions are to false' do
    rep = FactoryBot.build(:rm_repo_folder)
    rep.owner = @user3
    rep.save

    members = []
    members << @user2

    #Here user3 let user2 share this repo too
    options = {repo_item_permissions: {can_read: true, can_share: true}}

    # here user3 can share because he is the owner
    @user3.share_repo_item(rep, members, options)
    # here user2 should can share because he has the permission
    # But he has only the permission of read (can_read = true), He can't share with more permissions
    members = []
    members << @user1
    #Here the permissions should be : :can_read => true, and all others false
    @user2.share_repo_item(rep, members)

    sharing_of_user_1 = @user1.sharings.last

    expect(sharing_of_user_1.can_read?).to eq(false)
    expect(sharing_of_user_1.can_update?).to eq(false)
    expect(sharing_of_user_1.can_share?).to eq(false)
    #expect(@user1.sharings.count).to eq(1)
    #expect(@user2.sharings_owners.count).to eq(1)
  end

  it 'can share a repo_item with sharing and with restricted permissions' do
    rep = FactoryBot.build(:rm_repo_folder)
    rep.owner = @user3
    rep.save

    members = []
    members << @user2

    #Here user3 let user2 share this repo too
    options = {repo_item_permissions: {can_read: true, can_share: true}}

    # here user3 can share because he is the owner
    @user3.share_repo_item(rep, members, options)
    # here user2 should can share because he has the permission
    # But he has only the permission of read (can_read = true), He can't share with more permissions
    members = []
    members << @user1

    options = {repo_item_permissions: {can_read: true, can_update: true, can_share: true}}

    #Here the permissions should be : :can_read => true, :can_share => true and all others false
    @user2.share_repo_item(rep, members, options)

    sharing_of_user_1 = @user1.sharings.last

    expect(sharing_of_user_1.can_read?).to eq(true)
    expect(sharing_of_user_1.can_update?).to eq(false)
    expect(sharing_of_user_1.can_share?).to eq(true)
    #expect(@user1.sharings.count).to eq(1)
    #expect(@user2.sharings_owners.count).to eq(1)
  end

  it 'can share a repo_item with sharing permissions' do
    rep = FactoryBot.build(:rm_repo_folder)
    rep.owner = @user3
    rep.save

    members = []
    members << @user2

    options = {sharing_permissions: {can_add: true, can_remove: false}}

    # here user3 can share because he is the owner
    @user3.share_repo_item(rep, members, options)

    sharing_member_of_user_2 = @user2.sharings_members.last

    expect(sharing_member_of_user_2.can_add?).to eq(true)
    expect(sharing_member_of_user_2.can_remove?).to eq(false)
    #expect(@user1.sharings.count).to eq(1)
    #expect(@user2.sharings_owners.count).to eq(1)
  end

  # Todo implement with accepting nested set to true
  #it 'can share a repo_item with ancestor sharing permissions' do
  #  parent = FactoryBot.create(:repo_folder)
  #  parent.owner = @user3
  #  middle = @user3.create_folder('Middle', parent)
  #  children = @user3.create_folder('Children', middle)
  #
  #  file = FactoryBot.build(:rm_repo_file)
  #  file.owner = @user3
  #  file.save
  #
  #  children.add(file)
  #
  #  options = {repo_item_permissions: {can_read: true, can_update: true, can_share: false}}
  #  @user3.share_repo_item(parent, @user1, options)
  #
  #  options = {repo_item_permissions: {can_read: true, can_update: true, can_share: true}}
  #  @user3.share_repo_item(children, @user1, options)
  #
  #  @user1.share_repo_item(middle, @user2)
  #  expect(@user2.sharings.count).to eq(0)
  #  @user1.share_repo_item(file, @user2)
  #  expect(@user2.sharings.count).to eq(1)
  #end

  it 'can\'t share a nested sharing' do
    parent = @user1.create_folder('Parent')
    nested = @user1.create_folder('Nested', source_folder: parent)
    children = @user1.create_folder('Children', source_folder: nested)

    # @user1 own repository :
    #   |-- 'Parent'
    #   |  |-- 'Nested'
    #   |  |  |-- 'Children'

    @user1.share_repo_item(nested, @user2)

    expect(nested.can_be_shared_without_nesting?).to eq(true) # Returns true (because `nested` is shared but there is no nested sharing)
    expect(parent.can_be_shared_without_nesting?).to eq(false) # Returns false (because there is a sharing on one of his descendants)
    expect(parent.can_be_shared_without_nesting?).to eq(false) # Returns false (because there is a sharing on one of his ancestors)

    # Here we can't share 'Parent' or 'Children' because it already exist a nested sharing.
    expect(@user1.share_repo_item(parent, @user2)).to eq(false) # Returns false
    expect(parent.errors.messages).to eq({sharing: ['You can\'t share this item because another sharing exist on its ancestors or descendants']})

  end

  it 'can\'t share a repo_item with ancestor sharing permissions' do
    parent = FactoryBot.build(:rm_repo_folder)
    parent.owner = @user3
    parent.save
    middle = @user3.create_folder('Middle', source_folder: parent)
    children = @user3.create_folder('Children', source_folder: middle)

    file = FactoryBot.build(:rm_repo_file)
    file.owner = @user3
    file.save

    children.add(file)

    options = {repo_item_permissions: {can_read: true, can_update: true, can_share: true}}
    @user3.share_repo_item(parent, @user1, options)

    options = {repo_item_permissions: {can_read: true, can_update: true, can_share: true}}
    @user3.share_repo_item(children, @user1, options)

    @user1.share_repo_item(middle, @user2)
    expect(@user2.sharings.count).to eq(0)
    @user1.share_repo_item(file, @user2)
    expect(@user2.sharings.count).to eq(0)

  end

  it "can create a folder" do
    folder = @user1.create_folder('test folder')
    #folder = @user1.repo_items.last
    expect(folder.name).to eq('test folder')
    expect(folder.type).to eq('RepositoryManager::RepoFolder')
    expect(@user1.repo_items.folders.count).to eq(1)
  end

  it "can create a file" do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"))
    expect(file.name).to eq('textfile.txt')
    expect(@user1.repo_items.count).to eq(1)
    expect(@user1.repo_items.files.count).to eq(1)
  end

  it 'can put a creator for a specific sharing' do
    folder = @group1.create_folder('a')
    sharing = @group1.share_repo_item(folder, @user2, creator: @user1)

    expect(sharing.reload.owner).to eq(@group1)
    expect(sharing.creator).to eq(@user1)
  end

  it 'is by default owner = creator' do
    folder = @group1.create_folder('a')
    sharing = @group1.share_repo_item(folder, @user2)

    expect(sharing.reload.owner).to eq(@group1)
    expect(sharing.creator).to eq(@group1)
  end

  it 'returns only root repo items' do
    @user3.create_folder!
    @user3.create_folder!(nil, source_folder: @user3.create_folder!)
    expect(@user3.repo_items.count).to eq(3)
    expect(@user3.root_repo_items.count).to eq(2)
  end

end
