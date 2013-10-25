FactoryGirl.define do
  factory :repository do
    repository { fixture_file }
    #sequence :password do |n|
    #  'secret'
    #end
  end
end

def fixture_file
  File.open("#{Rails.root}/../fixture/textfile.txt")
end
