FactoryGirl.define do
  factory :repository do
    sequence :repository_type do
      :file
    end
    repository { fixture_file }
    #sequence :password do |n|
    #  'secret'
    #end
  end
end

def fixture_file
  File.open("#{Rails.root}/../fixture/textfile.txt")
end
