FactoryBot.define do
  factory :rm_repo_file, :class => RepositoryManager::RepoFile do
    file { fixture_file }
  end

  factory :rm_unzip, :class => RepositoryManager::RepoFile do
    file { fixture_unzip }
  end
end

def fixture_file
  File.open("#{Rails.root}/../fixture/textfile.txt")
end

def fixture_unzip
  File.open("#{Rails.root}/../fixture/unzip.zip")
end
