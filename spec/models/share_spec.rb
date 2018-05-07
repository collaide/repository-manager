require 'spec_helper'

describe 'Sharing' do

  before do
    @user1 = FactoryBot.create(:user)
    @user2 = FactoryBot.create(:user)
    @user3 = FactoryBot.create(:user)
    @user1_file = FactoryBot.build(:rm_repo_file)
    @user1_file.owner = @user1
    @user1_file.save
  end

  it 'can add a member in his own sharing' do
    sharing = @user1.share_repo_item(@user1_file, @user2, {sharing_permissions:{can_add: false, can_remove: false}})
    @user1.add_members_to(sharing, @user3)
    expect(@user3.shared_repo_items.count).to eq(1)
  end

  it 'can\'t add a member in a sharing without permission' do
    sharing = @user1.share_repo_item(@user1_file, @user2, {sharing_permissions:{can_add: false, can_remove: false}})
    @user2.add_members_to(sharing, @user3)
    expect(@user3.shared_repo_items.count).to eq(0)
  end

  it 'can add a member in a sharing with permission' do
    sharing = @user1.share_repo_item(@user1_file, @user2, {sharing_permissions:{can_add: true, can_remove: false}})
    @user2.add_members_to(sharing, @user3)
    expect(@user3.shared_repo_items.count).to eq(1)
  end

  it 'can remove a member in his own sharing' do
    sharing = @user1.share_repo_item(@user1_file, @user2, {sharing_permissions:{can_add: false, can_remove: false}})
    @user1.remove_members_from(sharing, @user2)
    expect(@user2.shared_repo_items.count).to eq(0)
  end


  it 'can remove a member in a sharing with permission' do
    sharing = @user1.share_repo_item(@user1_file, @user2, {sharing_permissions:{can_add: false, can_remove: true}})
    @user1.add_members_to(sharing, @user3)
    @user2.remove_members_from(sharing, @user3)
    expect(@user3.shared_repo_items.count).to eq(0)
  end

  it 'can\'t remove a member in a sharing without permission' do
    sharing = @user1.share_repo_item(@user1_file, @user2, {sharing_permissions:{can_add: false, can_remove: false}})
    @user1.add_members_to(sharing, @user3)
    @user2.remove_members_from(sharing, @user3)
    expect(@user3.shared_repo_items.count).to eq(1)
  end

  it 'can remove and add an array of members in a sharing with permission' do
    sharing = @user1.share_repo_item(@user1_file, @user2, {sharing_permissions:{can_add: true, can_remove: true}})
    user4 = FactoryBot.create(:user)
    @user2.add_members_to(sharing, [@user3, user4])
    expect(user4.shared_repo_items.count).to eq(1)
    @user2.remove_members_from(sharing, [@user3, user4])
    expect(user4.shared_repo_items.count).to eq(0)
  end

  it 'can\'t add a members in a sharing with permission that he has not' do
    sharing = @user1.share_repo_item(@user1_file, @user2, {sharing_permissions:{can_add: true, can_remove: false}})
    @user2.add_members_to(sharing, @user3, {can_add:true, can_remove:true})
    @user3.remove_members_from(sharing, @user2)
    expect(@user2.shared_repo_items.count).to eq(1)
  end

end