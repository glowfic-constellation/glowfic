FactoryGirl.define do
  sequence :username do |n|
    "JohnDoe#{n}"
  end

  factory :user, aliases: [:creator] do
    username
    password "password"
  end

  factory :board do
    creator
    name "test board"
  end

  factory :post do
    user
    board
    content "test content"
    subject "test subject"
  end
end
