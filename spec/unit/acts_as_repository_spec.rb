require 'spec_helper'

describe "ActsAsRepository" do
  it "should be the instance function test in user" do
    user = User.new
    expect("test: Hello World").to eq(user.test("Hello World"))
  end

  it "should be the instance function test in group" do
    group = Group.new
    expect("test: Hello World").to eq(group.test("Hello World"))
  end
end