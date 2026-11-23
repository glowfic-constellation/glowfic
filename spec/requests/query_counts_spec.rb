RSpec.describe "Query counts" do
  include QueryCountHelper

  # Each page must not run more queries when more records appear on it (no query per post/reply). Every record added
  # is as varied as possible (own user, character, alias, icon, section ...) so a lookup per distinct association
  # shows up as an extra query.
  describe "post page" do
    it "does not run a query per reply" do
      post = create(:post)
      add_reply = lambda do
        user = create(:user)
        character = create(:character, user: user)
        calias = create(:alias, character: character)
        create(:reply, post: post, user: user, character: character, character_alias: calias, icon: create(:icon, user: user))
      end
      add_reply.call

      expect_constant_queries("/posts/#{post.id}") { 3.times { add_reply.call } }
    end

    it "counts the post's and replies' edit history in one query" do
      post = create(:post)
      create(:reply, post: post)
      get "/posts/#{post.id}"
      expect(count_queries(matching: /FROM "audits"/) { get "/posts/#{post.id}" }).to eq(1)
    end

    it "shows the post's icon, character and author without loading them separately" do
      user = create(:user)
      character = create(:character, user: user, screenname: 'postscreenname')
      calias = create(:alias, character: character)
      icon = create(:icon, user: user)
      post = create(:post, user: user, character: character, character_alias: calias, icon: icon)
      create(:reply, post: post)
      get "/posts/#{post.id}"
      expect(response.body).to include(calias.name, 'postscreenname', icon.keyword, icon.url, user.username)
      expect(count_queries(matching: /FROM "(icons|characters|character_aliases)" WHERE "\w+"."id" = /) { get "/posts/#{post.id}" }).to eq(0)
      expect(count_queries(matching: /FROM "users" WHERE "users"."id" = /) { get "/posts/#{post.id}" }).to eq(0)

      reply = post.replies.first
      get "/replies/#{reply.id}"
      expect(response.body).to include(calias.name, 'postscreenname', icon.keyword, icon.url, user.username)
      expect(count_queries(matching: /FROM "(icons|characters|character_aliases)" WHERE "\w+"."id" = /) { get "/replies/#{reply.id}" }).to eq(0)
      expect(count_queries(matching: /FROM "posts" WHERE "posts"."id" = /) { get "/replies/#{reply.id}" }).to eq(0)
    end
  end

  describe "continuity page" do
    it "does not run a query per post" do
      board = create(:board)
      section = create(:board_section, board: board) # one query per section is by design, so the posts share one
      add_post = lambda do
        user = create(:user)
        post = create(:post, board: board, section: section, user: user, character: create(:character, user: user))
        create(:reply, post: post)
      end
      add_post.call

      expect_constant_queries("/boards/#{board.id}") { 3.times { add_post.call } }
    end
  end

  describe "recently updated" do
    it "does not run a query per post" do
      add_post = lambda do
        user = create(:user)
        post = create(:post, user: user, character: create(:character, user: user), board: create(:board))
        create(:reply, post: post, user: create(:user))
      end
      add_post.call

      expect_constant_queries("/posts") { 3.times { add_post.call } }
    end
  end
end
