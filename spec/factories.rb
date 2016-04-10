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

  factory :gallery do
    user
    name "test gallery"
  end

  factory :icon do
    user
    url "http://www.fakeicon.com"
    keyword "totally fake"

    factory :uploaded_icon do
      url { "http://glowfic-constellation.s3.amazonaws.com/users/#{user.id}/icons/nonsense-fakeimg.png" }
    end
  end

  factory :reply do
    user
    post
    content "test content"
  end
end
