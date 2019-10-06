FactoryBot.define do
  factory :user do
    sequence :nickname do |n|
      "User #{ n }"
    end
    sequence :email do |n|
      "user#{ n }@user.com"
    end
    sequence :password do |n|
      'secret'
    end
  end
end
