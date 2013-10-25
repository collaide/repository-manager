require 'spec_helper'

describe "ActsAsRepository through User" do

  before do
    @user1 = FactoryGirl.create(:user)
    @user2 = FactoryGirl.create(:user)
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

  it "can share a repository" do
    rep = FactoryGirl.create(:repository)

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