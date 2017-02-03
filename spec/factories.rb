FactoryGirl.define do
  sequence :username do |n|
    "JohnDoe#{n}"
  end

  factory :user, aliases: [:creator, :sender, :recipient] do
    username
    password "password"
    sequence :email do |n|
      "fake#{n}@faker.com"
    end

    factory :admin_user do
      id 1
    end
  end

  factory :board do
    creator
    name "test board"
  end

  factory :board_section do
    name "TestSection"
    board
  end

  factory :post do
    transient do
      with_icon false
      with_character false
      num_replies 0
    end
    user
    board
    content "test content"
    subject "test subject"
    before(:create) do |post, evaluator|
      post.character = create(:character, user: post.user) if evaluator.with_character
      post.icon = create(:icon, user: post.user) if evaluator.with_icon
      post.last_user = post.user
    end
    after(:create) do |post, evaluator|
      evaluator.num_replies.times do create(:reply, user: post.user, post: post) end
    end
  end

  factory :gallery do
    user
    name "test gallery"
    transient do
      icon_count 0
    end
    after(:create) do |gallery, evaluator|
      evaluator.icon_count.times do
        gallery.icons << create(:icon, user: gallery.user)
      end
    end
  end

  factory :icon do
    user
    url "http://www.fakeicon.com"
    keyword "totally fake"

    factory :uploaded_icon do
      url { "https://d1anwqy6ci9o1i.cloudfront.net/users/#{user.id}/icons/nonsense-fakeimg.png" }
    end
  end

  factory :reply do
    transient do
      with_icon false
      with_character false
    end
    user
    post
    content "test content"
    before(:create) do |reply, evaluator|
      reply.character = create(:character, user: reply.user) if evaluator.with_character
      reply.icon = create(:icon, user: reply.user) if evaluator.with_icon
    end
  end

  factory :reply_draft do
    user
    post
    content "test draft"
  end

  factory :character do
    user
    name 'test character'
    factory :template_character do
      template { build(:template, user: user) }
    end
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

  factory :tag do
    sequence :name do |n|
      "Tag#{n}"
    end
    user

    factory :setting, class: Setting do
      type 'Setting'
    end

    factory :content_warning, class: ContentWarning do
      type 'ContentWarning'
    end
  end

  factory :message do
    sender
    recipient
    message 'test message'
    sequence :subject do |n|
      "Message#{n}"
    end
  end

  factory :favorite do
    user
  end
end
