FactoryGirl.define do
  factory :repo_file do
    file { fixture_file }
    #sequence :password do |n|
    #  'secret'
    #end
  end
end

def fixture_file
  File.open("#{Rails.root}/../fixture/textfile.txt")
end
