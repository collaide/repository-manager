FactoryBot.define do
  factory :rm_repo_folder, :class => RepositoryManager::RepoFolder do
    sequence :name do |n|
      'Folder'
    end
  end
end
