FactoryGirl.define do
  factory :user, aliases: [:creator, :sender, :recipient] do
    sequence :username do |n|
      "JohnDoe#{n}"
    end
    password "password"
    sequence :email do |n|
      "fake#{n}@faker.com"
    end

    factory :admin_user do
      role_id 1
    end

    factory :mod_user do
      role_id 2
    end
  end

  factory :board do
    creator
    sequence :name do |n|
      "test board #{n}"
    end
  end

  factory :board_section do
    sequence :name do |n|
      "TestSection#{n}"
    end
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
    sequence :subject do |n|
      "test subject #{n}"
    end
    before(:create) do |post, evaluator|
      post.character = create(:character, user: post.user) if evaluator.with_character
      post.icon = create(:icon, user: post.user) if evaluator.with_icon
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
      url { "https://d1anwqy6ci9o1i.cloudfront.net/users%2F#{user.id}%2Ficons%2Fnonsense-fakeimg.png" }
      s3_key { "users/#{user.id}/icons/nonsense-fakeimg.png" }
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
    transient do
      with_default_icon false
    end
    user
    sequence :name do |n|
      "test character #{n}"
    end
    factory :template_character do
      template { build(:template, user: user) }
    end
    before(:create) do |character, evaluator|
      character.default_icon = create(:icon, user: character.user) if evaluator.with_default_icon
    end
  end

  factory :characters_gallery do
    character
    gallery
  end

  factory :alias, class: CharacterAlias do
    character
    sequence :name do |n|
      "TestAlias#{n}"
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

    factory :label, class: Label do
      type 'Label'
    end

    factory :setting, class: Setting do
      type 'Setting'
    end

    factory :content_warning, class: ContentWarning do
      type 'ContentWarning'
    end

    factory :gallery_group, class: GalleryGroup do
      type 'GalleryGroup'
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

  factory :board_view do
    user
    board
  end

  factory :post_view do
    user
    post
  end

  factory :index do
    user
    sequence :name do |n|
      "Index#{n}"
    end
  end

  factory :index_section do
    index
    sequence :name do |n|
      "IndexSection#{n}"
    end
  end
end
