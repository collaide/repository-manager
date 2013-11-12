require 'spec_helper'

describe 'Share' do

  before do
    @user1 = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)
    @user3 = FactoryGirl.create(:user)
    @user1_file = FactoryGirl.build(:app_file)
    @user1_file.owner = @user1
    @user1_file.save
  end

  it 'can add a item in his own share' do
    share = @user1.share(@user1_file, @user2, {share_permissions:{can_add: false, can_remove: false}})
    @user1.add_items_to(share, @user3)
    expect(@user3.shared_repositories.count).to eq(1)
  end

  it 'can\'t add an item in a share without permission' do
    share = @user1.share(@user1_file, @user2, {share_permissions:{can_add: false, can_remove: false}})
    @user2.add_items_to(share, @user3)
    expect(@user3.shared_repositories.count).to eq(0)
  end

  it 'can add an item in a share with permission' do
    share = @user1.share(@user1_file, @user2, {share_permissions:{can_add: true, can_remove: false}})
    @user2.add_items_to(share, @user3)
    expect(@user3.shared_repositories.count).to eq(1)
  end

  it 'can remove an item in his own share' do
    share = @user1.share(@user1_file, @user2, {share_permissions:{can_add: false, can_remove: false}})
    @user1.remove_items_from(share, @user2)
    expect(@user2.shared_repositories.count).to eq(0)
  end

  it 'can remove an item in a share with permission' do
    share = @user1.share(@user1_file, @user2, {share_permissions:{can_add: false, can_remove: true}})
    @user1.add_items_to(share, @user3)
    @user2.remove_items_from(share, @user3)
    expect(@user3.shared_repositories.count).to eq(0)
  end

  it 'can\'t remove an item in a share without permission' do
    share = @user1.share(@user1_file, @user2, {share_permissions:{can_add: false, can_remove: false}})
    @user1.add_items_to(share, @user3)
    @user2.remove_items_from(share, @user3)
    expect(@user3.shared_repositories.count).to eq(1)
  end

  it 'can remove and add an array of items in a share with permission' do
    share = @user1.share(@user1_file, @user2, {share_permissions:{can_add: true, can_remove: true}})
    user4 = FactoryGirl.create(:user)
    @user2.add_items_to(share, [@user3, user4])
    expect(user4.shared_repositories.count).to eq(1)
    @user2.remove_items_from(share, [@user3, user4])
    expect(user4.shared_repositories.count).to eq(0)
  end

  it 'can\'t add an items in a share with permission that he has not' do
    share = @user1.share(@user1_file, @user2, {share_permissions:{can_add: true, can_remove: false}})
    @user2.add_items_to(share, @user3, {can_add:true, can_remove:true})
    @user3.remove_items_from(share, @user2)
    expect(@user2.shared_repositories.count).to eq(1)
  end

end