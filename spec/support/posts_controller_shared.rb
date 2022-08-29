RSpec.shared_examples "logged out post list" do
  it "does not show user-only posts" do
    posts = create_list(:post, 2)
    create_list(:post, 2, privacy: :registered)
    create_list(:post, 2, privacy: :full_accounts)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(Post.all.count).to eq(6)
    expect(assigns(assign_variable)).to match_array(posts)
  end
end

RSpec.shared_examples "logged in post list" do
  let(:user) { create(:user) }
  let(:posts) { create_list(:post, 3) }

  before(:each) do
    login_as(user)
    posts
  end

  it "does not show access-locked or private threads" do
    create(:post, privacy: :private)
    create(:post, privacy: :access_list)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end

  it "shows access-locked and private threads if you have access" do
    posts << create(:post, user: user, privacy: :private)
    posts << create(:post, user: user, privacy: :access_list)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end

  it "does not show limited access threads to reader accounts" do
    user.update!(role_id: Permissible::READONLY)
    create(:post, privacy: :full_accounts)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end

  it "shows limited access threads to full accounts" do
    posts << create(:post, privacy: :full_accounts)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end

  it "does not show posts with blocked or blocking authors" do
    post1 = create(:post, authors_locked: true)
    post2 = create(:post, authors_locked: true)
    create(:block, blocking_user: user, blocked_user: post1.user, hide_them: :posts)
    create(:block, blocking_user: post2.user, blocked_user: user, hide_me: :posts)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end

  it "does not show posts with full blocked or blocking authors" do
    post1 = create(:post, authors_locked: true)
    post2 = create(:post, authors_locked: true)
    create(:block, blocking_user: user, blocked_user: post1.user, hide_them: :all)
    create(:block, blocking_user: post2.user, blocked_user: user, hide_me: :all)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end

  it "shows posts with a blocked (but not blocking) author with show_blocked" do
    post1 = create(:post, authors_locked: true)
    post2 = create(:post, authors_locked: true)
    create(:block, blocking_user: user, blocked_user: post1.user, hide_them: :posts)
    create(:block, blocking_user: post2.user, blocked_user: user, hide_me: :posts)
    params[:show_blocked] = true
    posts << post1
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end

  it "shows your own posts with blocked or but not blocking authors" do
    post1 = create(:post, authors_locked: true, author_ids: [user.id])
    create(:reply, post: post1, user: user)
    post2 = create(:post, authors_locked: true, author_ids: [user.id])
    create(:reply, post: post2, user: user)
    create(:block, blocking_user: user, blocked_user: post1.user, hide_them: :posts)
    create(:block, blocking_user: post2.user, blocked_user: user, hide_me: :posts)
    posts << post2
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end

  it "shows unlocked posts with incomplete blocking" do
    post1 = create(:post, authors_locked: false)
    post2 = create(:post, authors_locked: false)
    create(:block, blocking_user: user, blocked_user: post1.user, hide_them: :posts)
    create(:block, blocking_user: post2.user, blocked_user: user, hide_me: :posts)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts + [post1, post2])
  end

  it "does not show unlocked posts with full viewer-side blocking" do
    post1 = create(:post, authors_locked: false)
    create(:block, blocking_user: user, blocked_user: post1.user, hide_them: :all)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end

  it "shows unlocked posts with full viewer-side blocking as author" do
    post1 = create(:post, authors_locked: false)
    create(:reply, post: post1, user: user)
    posts << post1
    create(:block, blocking_user: user, blocked_user: post1.user, hide_them: :all)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end

  it "shows unlocked posts with full author-side blocking" do
    post1 = create(:post, authors_locked: false)
    posts << post1
    create(:block, blocking_user: post1.user, blocked_user: user, hide_me: :all)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(assigns(assign_variable)).to match_array(posts)
  end
end
