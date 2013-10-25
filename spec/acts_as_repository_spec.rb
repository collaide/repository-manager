require 'spec_helper'

describe "ActsAsRepository" do

  before do
    @user1 = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)
    @user3 = FactoryGirl.create(:user)
    @group1 = FactoryGirl.create(:group)
    @group2 = FactoryGirl.create(:group)
    @group3 = FactoryGirl.create(:group)
    @fileAlone = FactoryGirl.create(:repository)
  end

  it "should be associate with shares" do
    share = Share.create
    @user1.shares<<share
    expect(@user1.shares.last).to eq(share)
  end

  it "can add a file to repository" do
    #TODO
  end

  it "can add a folder to repository" do
    #TODO
  end

  it 'can share his own repository with other users' do
    rep = FactoryGirl.create(:repository)
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
    #expect(@user2.shares_owners.count).to eq(0)
    #expect(@user3.shares_owners.count).to eq(0)

  end

  it 'can not share a repository without shares and without the permission' do
    rep = FactoryGirl.create(:repository)
    rep.owner = @user3
    rep.save

    items = []
    items << @user2

    @user1.share(rep, items)

    expect(@user2.shares.count).to eq(0)
    expect(@user1.shares_owners.count).to eq(0)
  end

  it 'can not share a repository with share but without the permission' do
    rep = FactoryGirl.create(:repository)
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
    rep = FactoryGirl.create(:repository)
    rep.owner = @user3
    rep.save

    items = []
    items << @user2

    #Here user3 let user2 share this repo too
    repo_permissions = {:can_share => true}

    # here user3 can share because he is the owner
    @user3.share(rep, items, repo_permissions)
    # here user2 should can share because he has the authorisation
    items = []
    items << @user1
    @user2.share(rep, items)

    expect(@user1.shares.count).to eq(1)
    expect(@user2.shares_owners.count).to eq(1)
  end




  it "should be the instance function test in user" do
    user = User.new
    expect("test: Hello World").to eq(user.test("Hello World"))
  end

  it "should be the instance function test in group" do
    group = Group.new
    expect("test: Hello World").to eq(group.test("Hello World"))
  end

end