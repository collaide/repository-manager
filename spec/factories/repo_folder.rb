FactoryGirl.define do
  factory :repo_folder do
    sequence :name do |n|
      'Folder'
    end
  end
end
