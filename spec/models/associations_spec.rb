require 'spec_helper'

describe "Associations" do

  it "test if user can have a own file" do
    user = FactoryBot.build(:user)
    file = RepositoryManager::RepoItem.new
    file.owner = user
    expect(file.owner).to eq(user)
  end

  it "test if user can have a own sharing" do
    user = FactoryBot.build(:user)
    sharing = RepositoryManager::Sharing.new
    sharing.owner = user
    expect(sharing.owner).to eq(user)
  end

  it "should be possible for a user to share a file" do

    user = FactoryBot.create(:user)
    user2 = FactoryBot.create(:user)
    expect(user2.sharings.count).to eq(0)
    expect(user.repo_items.count).to eq(0)

    file = RepositoryManager::RepoItem.new
    file.owner = user
    file.save

    #pp user.repo_items

    sharing = RepositoryManager::Sharing.new(can_read:true, can_create:true)
    sharing.owner = user
    sharing.save
    file.sharings << sharing
    sharings_member = RepositoryManager::SharingsMember.new
    sharings_member.member=user2
    sharing.sharings_members << sharings_member

    #expect(user2.sharings.count).to eq(0)
    #expect(file.sharings.count).to eq(0)

    #RepositoryManager::SharingsMember.save
    #sharing.save
    file.save

    expect(user.repo_items.count).to eq(1)
    expect(user2.sharings.count).to eq(1)
    expect(file.sharings.count).to eq(1)
  end

  it "should be possible for a group to share a file" do

    user = FactoryBot.create(:user)
    user2 = FactoryBot.create(:user)
    group = FactoryBot.create(:group)
    group2 = FactoryBot.create(:group)
    expect(group.sharings.count).to eq(0)
    expect(group.repo_items.count).to eq(0)

    file = RepositoryManager::RepoItem.new
    file.owner = user
    file.save

    #pp user.repo_items

    sharing = RepositoryManager::Sharing.new(can_read:true, can_create:true)
    sharing.owner = group
    sharing.save
    file.sharings << sharing
    sm = RepositoryManager::SharingsMember.new
    sm.member=group2
    sm.save
    sharing.sharings_members << sm

    #expect(user2.sharings.count).to eq(0)
    #expect(file.sharings.count).to eq(0)

    #RepositoryManager::SharingsMember.save
    #sharing.save
    file.save

    expect(user.repo_items.count).to eq(1)
    expect(user2.sharings.count).to eq(0)
    expect(user.sharings.count).to eq(0)
    expect(group.repo_items.count).to eq(0)
    expect(group.sharings.count).to eq(0)
    #Il est auteur d'un sharing
    expect(group.sharings_owners.count).to eq(1)
    expect(group2.sharings.count).to eq(1)
    expect(file.sharings.count).to eq(1)
  end

end