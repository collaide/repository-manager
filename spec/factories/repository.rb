FactoryGirl.define do
  factory :repository do
    attachment { fixture_file }
    #sequence :password do |n|
    #  'secret'
    #end
  end
end

def fixture_file
  File.open("#{Rails.root}/spec/fixture/textfile.txt")
end
