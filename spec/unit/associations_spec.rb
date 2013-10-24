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
    user = FactoryGirl.build(:user)
    user2 = FactoryGirl.build(:user)
    file = AppFile.new
    file.owner = user
    share = Share.new(can_read:true, can_create:true)
    share.owner = user
    file.shares << share
    shareItem = SharesItem.new
    shareItem.item=user2
    share.shares_items << shareItem

    #TODO rendre ça plus facile
  end

  #def test_of_share_a_file
  #  user1 = User.new
  #  user2 = User.new
  #  share = Share.new
  #  share.owner = user
  #  assert_equal share.owner, user
  #end



end