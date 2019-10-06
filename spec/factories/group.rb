FactoryBot.define do
  factory :group do
    sequence :name do |n|
      "Group #{ n }"
    end
  end
end
