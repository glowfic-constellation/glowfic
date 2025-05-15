RSpec.describe BookmarksController, 'POST create' do
  let(:user) { create(:user) }
  let(:reply) { create(:reply, user: user) }

  it "requires login" do
    post :create
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires reply ID" do
    login
    post :create
    expect(response).to redirect_to(posts_path)
    expect(flash[:error]).to eq("Reply not selected.")
  end

  it "requires valid reply" do
    login
    post :create, params: { at_id: -1 }
    expect(response).to redirect_to(posts_path)
    expect(flash[:error]).to eq("Reply not found.")
  end

  it "succeeds with a valid reply" do
    login_as(user)
    post :create, params: { at_id: reply.id }

    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:success]).to eq('Bookmark added.')
    bookmark = Bookmark.order(:id).last
    expect(bookmark.user).to eq(user)
    expect(bookmark.reply).to eq(reply)
    expect(bookmark.post).to eq(reply.post)
    expect(bookmark.type).to eq("reply_bookmark")
    expect(bookmark.name).to be_nil
  end

  it "succeeds with name param" do
    login
    post :create, params: { at_id: reply.id, name: "new bookmark" }

    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:success]).to eq('Bookmark added.')
    bookmark = Bookmark.order(:id).last
    expect(bookmark.name).to eq("new bookmark")
    expect(bookmark.public).to be false
  end

  it "succeeds with public param" do
    login
    post :create, params: { at_id: reply.id, public: true }

    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:success]).to eq('Bookmark added.')
    bookmark = Bookmark.order(:id).last
    expect(bookmark.name).to be_nil
    expect(bookmark.public).to be true
  end

  it "fails if already exists" do
    login_as(user)
    existing_bookmark = create(:bookmark, user: user, reply: reply)
    post :create, params: { at_id: reply.id }

    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:error]).to eq("Bookmark already exists.")
    newest_bookmark = Bookmark.order(:id).last
    expect(newest_bookmark).to eq(existing_bookmark)
  end

  it "allows multiple users to bookmark the same reply" do
    existing_bookmark = create(:bookmark, user: user, reply: reply)
    login
    post :create, params: { at_id: reply.id }

    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:success]).to eq('Bookmark added.')
    new_bookmark = Bookmark.order(:id).last
    expect(new_bookmark).not_to eq(existing_bookmark)
    expect(new_bookmark.user).not_to eq(user)
    expect(new_bookmark.reply).to eq(existing_bookmark.reply)
    expect(new_bookmark.post).to eq(existing_bookmark.post)
  end

  it "allows user to bookmark multiple replies" do
    login

    post :create, params: { at_id: reply.id }
    bookmark = Bookmark.order(:id).last

    second_reply = create(:reply)
    post :create, params: { at_id: second_reply.id }
    expect(response).to redirect_to(reply_url(second_reply, anchor: "reply-#{second_reply.id}"))
    expect(flash[:success]).to eq('Bookmark added.')
    second_bookmark = Bookmark.order(:id).last

    expect(second_bookmark).not_to eq(bookmark)
    expect(second_bookmark.user).to eq(bookmark.user)
    expect(second_bookmark.reply).not_to eq(bookmark.reply)
    expect(second_bookmark.reply).to eq(second_reply)
  end
end
