class ErrorEnumerable
  # returns an enumerable that repeatedly raises an error when it reaches the
  # end of the range - even when used as an enumerator.

  include Enumerable

  def initialize(range, err)
    @range = range
    @err = err
    @stopped = false
  end

  def each
    raise StopIteration.new(@err) if @stopped
    @range.each { |i| yield i }
    @stopped = true
    raise StopIteration.new(@err)
  end
end

def ordered_numbers
  # used in sequences to ensure an ordered list of (padded) numbers,
  # which returns an error when we reach the limit of the sequence.
  ErrorEnumerable.new(
    "00000".."99999",
    "FactoryBot sequence exhausted - please increment the range of ordered_numbers in spec/factories.rb",
  ).to_enum
end

FactoryBot.define do
  factory :user, aliases: [:creator, :sender, :recipient, :blocking_user, :blocked_user] do
    sequence :username, ordered_numbers do |n|
      "JohnDoe#{n}"
    end
    password { "password" }
    sequence :email do |n|
      "fake#{n}@faker.com"
    end
    tos_version { User::CURRENT_TOS_VERSION }

    factory :admin_user do
      role_id { 1 }
    end

    factory :mod_user do
      role_id { 2 }
    end

    factory :importing_user do
      role_id { 3 }
    end

    factory :reader_user do
      role_id { 5 }
    end
  end

  factory :board do
    creator
    authors_locked { writer_ids.present? || writers.present? }
    sequence :name, ordered_numbers do |n|
      "test board #{n}"
    end
  end

  factory :board_section do
    sequence :name, ordered_numbers do |n|
      "TestSection#{n}"
    end
    board
  end

  factory :post do
    transient do
      with_icon { false }
      with_character { false }
      num_replies { 0 }
    end
    user
    board
    description { "" }
    editor_mode { 'rtf' }
    content { "test content" }
    sequence :subject, ordered_numbers do |n|
      "test subject #{n}"
    end
    before(:create) do |post, evaluator|
      post.character = create(:character, user: post.user) if evaluator.with_character
      post.icon = create(:icon, user: post.user) if evaluator.with_icon
    end

    after(:create) do |post, evaluator|
      evaluator.num_replies.times { create(:reply, user: post.user, post: post) }
    end
  end

  factory :gallery do
    user
    sequence :name, ordered_numbers do |n|
      "test gallery #{n}"
    end
    transient do
      icon_count { 0 }
    end
    after(:create) do |gallery, evaluator|
      evaluator.icon_count.times do
        gallery.icons << create(:icon, user: gallery.user)
      end
    end
  end

  factory :icon do
    user
    url { "http://www.fakeicon.com" }
    sequence :keyword, ordered_numbers do |n|
      "totally fake #{n}"
    end

    factory :uploaded_icon do
      sequence :url, ordered_numbers do |n|
        "https://d1anwqy6ci9o1i.cloudfront.net/users%2F#{user.id}%2Ficons%2Fnonsense-fakeimg-#{n}.png"
      end
      sequence :s3_key, ordered_numbers do |n|
        "users/#{user.id}/icons/nonsense-fakeimg-#{n}.png"
      end
    end
  end

  factory :reply do
    transient do
      with_icon { false }
      with_character { false }
    end
    user
    post
    editor_mode { 'rtf' }
    sequence :content, ordered_numbers do |n|
      "test content #{n}"
    end
    before(:create) do |reply, evaluator|
      reply.character = create(:character, user: reply.user) if evaluator.with_character
      reply.icon = create(:icon, user: reply.user) if evaluator.with_icon
    end
  end

  factory :reply_draft do
    user
    post
    editor_mode { 'rtf' }
    sequence :content, ordered_numbers do |n|
      "test draft #{n}"
    end
  end

  factory :character do
    transient do
      with_default_icon { false }
    end
    user
    sequence :name, ordered_numbers do |n|
      "test character #{n}"
    end
    factory :template_character do
      template { association(:template, user: user) }
    end
    before(:create) do |character, evaluator|
      character.default_icon = create(:icon, user: character.user) if evaluator.with_default_icon
    end
  end

  factory :characters_gallery do
    character
    gallery
  end

  factory :alias, class: :character_alias do
    character
    sequence :name, ordered_numbers do |n|
      "TestAlias#{n}"
    end
  end

  factory :template do
    user
    sequence :name, ordered_numbers do |n|
      "test template #{n}"
    end
  end

  factory :character_group do
    user
    sequence :name, ordered_numbers do |n|
      "test character group #{n}"
    end
  end

  factory :password_reset do
    user
    factory :expired_password_reset do
      created_at { 3.days.ago }
    end
    factory :used_password_reset do
      used { true }
    end
  end

  factory :tag do
    sequence :name, ordered_numbers do |n|
      "Tag#{n}"
    end
    user

    factory :label, class: :label do
      type { 'Label' }
    end

    factory :setting, class: :setting do
      type { 'Setting' }
    end

    factory :content_warning, class: :content_warning do
      type { 'ContentWarning' }
    end

    factory :gallery_group, class: :gallery_group do
      type { 'GalleryGroup' }
    end
  end

  factory :font, class: :font do
    name { "Example font" }
  end

  factory :message do
    sender
    recipient
    message { 'test message' }
    sequence :subject, ordered_numbers do |n|
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

  factory :post_author, class: 'Post::Author' do
    user
    post
  end

  factory :post_view, class: 'Post::View' do
    user
    post
  end

  factory :index do
    user
    sequence :name, ordered_numbers do |n|
      "Index#{n}"
    end
  end

  factory :index_section do
    index
    sequence :name, ordered_numbers do |n|
      "IndexSection#{n}"
    end
  end

  factory :index_post do
    index
    post
  end

  factory :block do
    blocking_user
    blocked_user
  end

  factory :news do
    user { association(:mod_user) }
    sequence :content, ordered_numbers do |n|
      "content for news post #{n}"
    end
  end
end
