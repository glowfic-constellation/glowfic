FactoryGirl.define do
  sequence :username do |n|
    "JohnDoe#{n}"
  end

  factory :user, aliases: [:creator] do
    username
    password "password"

    factory :user_with_email do
      email "fake@faker.com"
    end
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

  factory :character do
    user
    name 'test character'
  end

  factory :template do
    user
    name 'test template'
  end

  factory :password_reset do
    user
    factory :expired_password_reset do
      created_at { 3.days.ago }
    end
    factory :used_password_reset do
      used true
    end
  end
end
