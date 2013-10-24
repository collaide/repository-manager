require 'spec_helper'

describe "Associations" do

  it "test if user can have a own file" do
    user = FactoryGirl.build(:user)
    file = AppFile.new
    file.owner = user
    expect(file.owner).to eq(user)
  end

  it "test if user can have a own share" do
    user = User.new
    share = Share.new
    share.owner = user
    expect(share.owner).to eq(user)
  end

  it "should be possible for a user to share a file" do

    user = FactoryGirl.create(:user)
    user2 = FactoryGirl.create(:user)
    expect(user2.shares.count).to eq(0)
    expect(user.app_files.count).to eq(0)

    file = AppFile.new
    file.owner = user

    #pp user.app_files

    share = Share.new(can_read:true, can_create:true)
    share.owner = user
    file.shares << share
    shareItem = SharesItem.new
    shareItem.item=user2
    share.shares_items << shareItem

    #expect(user2.shares.count).to eq(0)
    #expect(file.shares.count).to eq(0)

    #shareItem.save
    #share.save
    file.save

    expect(user.app_files.count).to eq(1)
    expect(user2.shares.count).to eq(1)
    expect(file.shares.count).to eq(1)
  end

  it "should be possible for a group to share a file" do

    user = FactoryGirl.create(:user)
    user2 = FactoryGirl.create(:user)
    group = FactoryGirl.create(:group)
    group2 = FactoryGirl.create(:group)
    expect(group.shares.count).to eq(0)
    expect(group.app_files.count).to eq(0)

    file = AppFile.new
    file.owner = user

    #pp user.app_files

    share = Share.new(can_read:true, can_create:true)
    share.owner = group
    file.shares << share
    shareItem = SharesItem.new
    shareItem.item=group2
    share.shares_items << shareItem

    #expect(user2.shares.count).to eq(0)
    #expect(file.shares.count).to eq(0)

    #shareItem.save
    #share.save
    file.save

    expect(user.app_files.count).to eq(1)
    expect(user2.shares.count).to eq(0)
    expect(user.shares.count).to eq(0)
    expect(group.app_files.count).to eq(0)
    expect(group.shares.count).to eq(0)
    #Il est auteur d'un share
    expect(group.shares_owners.count).to eq(1)
    expect(group2.shares.count).to eq(1)
    expect(file.shares.count).to eq(1)
  end

end