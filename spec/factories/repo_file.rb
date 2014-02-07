FactoryGirl.define do
  factory :rm_repo_file, :class => RepositoryManager::RepoFile do
    file { fixture_file }
    #sequence :password do |n|
    #  'secret'
    #end
  end
end

def fixture_file
  File.open("#{Rails.root}/../fixture/textfile.txt")
end
