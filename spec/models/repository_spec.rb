require 'spec_helper'

describe 'Repository' do

  before do
    @user1 = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)
    @file_alone = FactoryGirl.create(:repository)
  end

  it "can create a folder" do
    @file_alone.owner = @user1
    @folder = Repository.new

    @folder.name = 'Folder'
    #@folder.repository_type = :folder

    @folder.children = @file_alone

    @folder.save

    expect(@folder.has_children?).to eq(true)

  end
end