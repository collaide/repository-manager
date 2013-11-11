require 'spec_helper'

describe "HasRepository" do

  before do
    @user1 = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)
    @user3 = FactoryGirl.create(:user)
    @group1 = FactoryGirl.create(:group)
    #@group2 = FactoryGirl.create(:group)
    #@group3 = FactoryGirl.create(:group)
    #@fileAlone = FactoryGirl.create(:app_file)
  end

  it "should be associate with shares" do
    share = Share.create
    @user1.shares << share
    expect(@user1.shares.last).to eq(share)
  end

  it "can add a file to repository" do
    #TODO
  end

  it "can add a folder to repository" do
    #TODO
  end

  it 'can share his own repository with other users' do
    rep = FactoryGirl.create(:app_file)
    rep.owner = @user1
    rep.save

    #expect(@user1.shares.count).to eq(0)
    #expect(@user2.shares.count).to eq(0)
    #expect(@user3.shares.count).to eq(0)
    #expect(@user1.shares_owners.count).to eq(0)
    #expect(@user2.shares_owners.count).to eq(0)
    #expect(@user3.shares_owners.count).to eq(0)

    #Add the 2 users to items
    items = []
    items << @user2
    items << @user3

    @user1.share(rep, items)

    #expect(@user1.shares.count).to eq(0)
    expect(@user2.shares.count).to eq(1)
    expect(@user3.shares.count).to eq(1)
    expect(@user1.shares_owners.count).to eq(1)
    expect(@user2.repositories.count).to eq(0)
    #expect(@user2.shares_repositories.count).to eq(1)

    #expect(@user2.shares_owners.count).to eq(0)
    #expect(@user3.shares_owners.count).to eq(0)

  end

  it 'can not share a repository without shares and without the permission' do
    rep = FactoryGirl.create(:app_file)
    rep.owner = @user3
    rep.save

    items = []
    items << @user2

    @user1.share(rep, items)

    expect(@user2.shares.count).to eq(0)
    expect(@user1.shares_owners.count).to eq(0)
  end

  it 'can not share a repository with share but without the permission' do
    rep = FactoryGirl.create(:folder)
    rep.owner = @user3
    rep.save

    items = []
    items << @user2

    # here user3 can share because he is the owner
    @user3.share(rep, items)
    # here user2 should can share because he has the authorisation
    items = []
    items << @user1
    @user2.share(rep, items)

    expect(@user1.shares.count).to eq(0)
    expect(@user2.shares_owners.count).to eq(0)
  end

  it 'can share a repository with share and with the permission' do
    rep = FactoryGirl.create(:folder)
    rep.owner = @user3
    rep.save

    items = []
    items << @user2

    #Here user3 let user2 share this repo too
    repo_permissions = {can_share: true}

    # here user3 can share because he is the owner
    @user3.share(rep, items, repo_permissions)
    # here user2 should can share because he has the authorisation
    items = []
    items << @user1
    @user2.share(rep, items)

    expect(@user1.shares.count).to eq(1)
    expect(@user2.shares_owners.count).to eq(1)
  end

  it 'default shares permissions are to false' do
    rep = FactoryGirl.create(:folder)
    rep.owner = @user3
    rep.save

    items = []
    items << @user2

    #Here user3 let user2 share this repo too
    repo_permissions = {can_read: true, can_share: true}

    # here user3 can share because he is the owner
    @user3.share(rep, items, repo_permissions)
    # here user2 should can share because he has the authorisation
    # But he has only the authorisation of read (can_read = true), He can't share with more permissions
    items = []
    items << @user1
    #Here the permissions should be : :can_read => true, and all others false
    @user2.share(rep, items)

    share_of_user_1 = @user1.shares.last

    expect(share_of_user_1.can_read).to eq(false)
    expect(share_of_user_1.can_update).to eq(false)
    expect(share_of_user_1.can_share).to eq(false)
    #expect(@user1.shares.count).to eq(1)
    #expect(@user2.shares_owners.count).to eq(1)
  end

  it 'can share a repository with share and with restricted permissions' do
    rep = FactoryGirl.create(:folder)
    rep.owner = @user3
    rep.save

    items = []
    items << @user2

    #Here user3 let user2 share this repo too
    repo_permissions = {can_read: true, can_share: true}

    # here user3 can share because he is the owner
    @user3.share(rep, items, repo_permissions)
    # here user2 should can share because he has the authorisation
    # But he has only the authorisation of read (can_read = true), He can't share with more permissions
    items = []
    items << @user1

    repo_permissions = {can_read: true, can_update: true, can_share: true}

    #Here the permissions should be : :can_read => true, :can_share => true and all others false
    @user2.share(rep, items, repo_permissions)

    share_of_user_1 = @user1.shares.last

    expect(share_of_user_1.can_read).to eq(true)
    expect(share_of_user_1.can_update).to eq(false)
    expect(share_of_user_1.can_share).to eq(true)
    #expect(@user1.shares.count).to eq(1)
    #expect(@user2.shares_owners.count).to eq(1)
  end

  it 'can share a repository with share permissions' do
    rep = FactoryGirl.create(:folder)
    rep.owner = @user3
    rep.save

    items = []
    items << @user2

    share_permissions = {can_add: true, can_remove: false}

    # here user3 can share because he is the owner
    @user3.share(rep, items, nil, share_permissions)

    share_item_of_user_2 = @user2.shares_items.last

    expect(share_item_of_user_2.can_add).to eq(true)
    expect(share_item_of_user_2.can_remove).to eq(false)
    #expect(@user1.shares.count).to eq(1)
    #expect(@user2.shares_owners.count).to eq(1)
  end

  it 'can share a repository with ancestor share permissions' do
    parent = FactoryGirl.create(:folder)
    parent.owner = @user3
    middle = @user3.create_folder('Middle', parent)
    children = @user3.create_folder('Children', middle)

    file = FactoryGirl.build(:app_file)
    file.owner = @user3
    file.save

    children.add_repository(file)

    repo_permissions = {can_read: true, can_update: true, can_share: false}
    @user3.share(parent, @user1, repo_permissions)

    repo_permissions = {can_read: true, can_update: true, can_share: true}
    @user3.share(children, @user1, repo_permissions)

    @user1.share(middle, @user2)
    expect(@user2.shares.count).to eq(0)
    @user1.share(file, @user2)
    expect(@user2.shares.count).to eq(1)
  end

  it "can create a folder" do
    folder = @user1.create_folder('test folder')
    #folder = @user1.repositories.last
    expect(folder.name).to eq('test folder')
    expect(folder.type).to eq('Folder')
  end

  it "can create a file" do
    file = @user1.create_file(File.open("#{Rails.root}/../fixture/textfile.txt"))
    expect(file.name).to eq('textfile.txt')
    expect(@user1.repositories.count).to eq(1)
  end

end