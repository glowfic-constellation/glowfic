require "spec_helper"

RSpec.shared_examples "reply" do
  let(:user) { create(:user) }


end

RSpec.describe Reply::Saver do
  let(:user) { create(:user) }

  describe "create" do
    it "requires valid post" do
      login
      post :create
      expect(response).to redirect_to(posts_url)
      expect(flash[:error][:message]).to eq("Your reply could not be saved because of the following problems:")
    end

    it "requires post read" do
      reply_post = create(:post)
      login_as(reply_post.user)
      reply_post.mark_read(reply_post.user)
      create(:reply, post: reply_post)

      post :create, params: { reply: {post_id: reply_post.id, user_id: reply_post.user_id} }
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("There has been 1 new reply since you last viewed this post.")
    end

    it "handles multiple creations with unread warning" do
      reply_post = create(:post)
      login_as(reply_post.user)
      reply_post.mark_read(reply_post.user)
      create(:reply, post: reply_post) # last_seen

      post :create, params: { reply: {post_id: reply_post.id, user_id: reply_post.user_id} }
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("There has been 1 new reply since you last viewed this post.")

      create(:reply, post: reply_post)
      create(:reply, post: reply_post)

      post :create, params: { reply: {post_id: reply_post.id, user_id: reply_post.user_id} }
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("There have been 2 new replies since you last viewed this post.")
    end

    it "handles multiple creations by user" do
      reply_post = create(:post)
      login_as(reply_post.user)
      dupe_reply = create(:reply, user: reply_post.user, post: reply_post)
      reply_post.mark_read(reply_post.user, dupe_reply.created_at + 1.second, true)

      post :create, params: { reply: {post_id: reply_post.id, user_id: reply_post.user_id, content: dupe_reply.content} }
      expect(response).to have_http_status(200)
      expect(flash[:error]).to eq("This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional.")

      post :create, params: { reply: {post_id: reply_post.id, user_id: reply_post.user_id, content: dupe_reply.content}, allow_dupe: true }
      expect(response).to have_http_status(302)
      expect(flash[:success]).to eq("Posted!")
    end

    it "requires valid params if read" do
      user = create(:user)
      login_as(user)
      character = create(:character)
      reply_post = create(:post)
      reply_post.mark_read(user, reply_post.created_at + 1.second, true)

      expect(character.user_id).not_to eq(user.id)
      post :create, params: { reply: {character_id: character.id, post_id: reply_post.id} }
      expect(response).to redirect_to(post_url(reply_post))
      expect(flash[:error][:message]).to eq("Your reply could not be saved because of the following problems:")
    end

    it "saves a new reply successfully if read" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post)
      reply_post.mark_read(user, reply_post.created_at + 1.second, true)
      expect(Reply.count).to eq(0)
      char = create(:character, user: user)
      icon = create(:icon, user: user)
      calias = create(:alias, character: char)

      post :create, params: { reply: {post_id: reply_post.id, content: 'test!', character_id: char.id, icon_id: icon.id, character_alias_id: calias.id} }

      reply = Reply.first
      expect(reply).not_to be_nil
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(flash[:success]).to eq("Posted!")
      expect(reply.user).to eq(user)
      expect(reply.post).to eq(reply_post)
      expect(reply.content).to eq('test!')
      expect(reply.character_id).to eq(char.id)
      expect(reply.icon_id).to eq(icon.id)
      expect(reply.character_alias_id).to eq(calias.id)
    end

    it "allows you to reply to a post you created" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post, user: user)
      reply_post.mark_read(user, reply_post.created_at + 1.second, true)
      expect(Reply.count).to eq(0)

      post :create, params: { reply: {post_id: reply_post.id, content: 'test content!'} }
      reply = Reply.first
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(reply).not_to be_nil
      expect(flash[:success]).to eq('Posted!')
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content!')
    end

    it "allows you to reply to join a post you did not create" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post)
      reply_post.mark_read(user, reply_post.created_at + 1.second, true)
      expect(Reply.count).to eq(0)

      post :create, params: { reply: {post_id: reply_post.id, content: 'test content again!'} }
      reply = Reply.first
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(reply).not_to be_nil
      expect(flash[:success]).to eq('Posted!')
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content again!')
    end

    it "allows you to reply to a post you already joined" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post)
      reply_old = create(:reply, post: reply_post, user: user)
      reply_post.mark_read(user, reply_old.created_at + 1.second, true)
      expect(Reply.count).to eq(1)

      post :create, params: { reply: {post_id: reply_post.id, content: 'test content the third!'} }
      expect(Reply.count).to eq(2)
      reply = Reply.ordered.last
      expect(reply).not_to eq(reply_old)
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(flash[:success]).to eq('Posted!')
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content the third!')
    end

    it "allows you to reply to a closed post you already joined" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post)
      reply_old = create(:reply, post: reply_post, user: user)
      reply_post.mark_read(user, reply_old.created_at + 1.second, true)
      expect(Reply.count).to eq(1)
      reply_post.update!(authors_locked: true)

      post :create, params: { reply: {post_id: reply_post.id, content: 'test content the third!'} }
      expect(Reply.count).to eq(2)
      reply = Reply.order(id: :desc).first
      expect(reply).not_to eq(reply_old)
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(flash[:success]).to eq('Posted!')
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content the third!')
    end

    it "allows replies from authors in a closed post" do
      user = create(:user)
      other_user = create(:user)
      login_as(user)
      reply_post = create(:post, user: other_user, tagging_authors: [user, other_user], authors_locked: true)
      reply_post.mark_read(user)
      post :create, params: { reply: {post_id: reply_post.id, content: 'test content!'} }
      expect(Reply.count).to eq(1)
    end

    it "allows replies from owner in a closed post" do
      user = create(:user)
      other_user = create(:user)
      login_as(user)
      other_post = create(:post, user: user, tagging_authors: [user, other_user], authors_locked: true)
      other_post.mark_read(user)
      post :create, params: { reply: {post_id: other_post.id, content: 'more test content!'} }
      expect(Reply.count).to eq(1)
    end

    it "adds authors correctly when a user replies to an open thread" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post)
      reply_post.mark_read(user)
      Timecop.freeze(Time.zone.now) do
        post :create, params: { reply: {post_id: reply_post.id, content: 'test content!'} }
      end
      expect(Reply.count).to eq(1)
      expect(reply_post.tagging_authors).to match_array([user, reply_post.user])
      post_author = reply_post.tagging_post_authors.find_by(user: user)
      expect(post_author.user).to eq(user)
      expect(post_author.joined).to eq(true)
      expect(post_author.joined_at).to be_the_same_time_as(Reply.last.created_at)
      expect(post_author.can_owe).to eq(true)
    end

    it "handles multiple replies to an open thread correctly" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post)
      expect(reply_post.tagging_authors.count).to eq(1)
      old_reply = create(:reply, post: reply_post, user: user)
      reply_post.reload
      expect(reply_post.tagging_authors).to include(user)
      expect(reply_post.tagging_authors.count).to eq(2)
      expect(reply_post.joined_authors).to include(user)
      expect(reply_post.joined_authors.count).to eq(2)
      expect(Reply.count).to eq(1)
      reply_post.mark_read(user, old_reply.created_at + 1.second, true)
      post :create, params: { reply: {post_id: reply_post.id, content: 'test content!'} }
      expect(Reply.count).to eq(2)
      expect(reply_post.tagging_authors).to match_array([user, reply_post.user])
    end

    it "handles trying to reply to a closed thread as a non-author correctly" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post, authors_locked: true)
      reply_post.mark_read(user)
      post :create, params: { reply: {post_id: reply_post.id, content: 'test'} }
      expect(flash[:error][:message]).to eq("Your reply could not be saved because of the following problems:")
      expect(flash[:error][:array]).to eq(["User #{user.username} cannot write in this post"])
    end

    it "sets reply_order correctly on the first reply" do
      reply_post = create(:post)
      login_as(reply_post.user)
      reply_post.mark_read(reply_post.user)
      searchable = 'searchable content'
      post :create, params: { reply: {post_id: reply_post.id, content: searchable} }
      reply = reply_post.replies.ordered.last
      expect(reply.content).to eq(searchable)
      expect(reply.reply_order).to eq(0)
    end

    it "sets reply_order correctly with an existing reply" do
      reply_post = create(:post)
      login_as(reply_post.user)
      create(:reply, post: reply_post)
      reply_post.mark_read(reply_post.user)
      searchable = 'searchable content'
      post :create, params: { reply: {post_id: reply_post.id, content: searchable} }
      reply = reply_post.replies.ordered.last
      expect(reply.content).to eq(searchable)
      expect(reply.reply_order).to eq(1)
    end

    it "sets reply_order correctly with multiple existing replies" do
      reply_post = create(:post)
      login_as(reply_post.user)
      create(:reply, post: reply_post)
      create(:reply, post: reply_post)
      reply_post.mark_read(reply_post.user)
      searchable = 'searchable content'
      post :create, params: { reply: {post_id: reply_post.id, content: searchable} }
      reply = reply_post.replies.ordered.last
      expect(reply.content).to eq(searchable)
      expect(reply.reply_order).to eq(2)
    end
  end

  describe "update" do
    let(:reply) { create(:character, user: user) }
    let(:params) { ActionController::Parameters.new({ id: reply.id }) }

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to eq(true)

      reply.post.privacy = Concealable::PRIVATE
      reply.post.save!
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      put :update, params: { id: reply.id }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "requires reply access" do
      reply = create(:reply)
      login
      put :update, params: { id: reply.id }
      expect(response).to redirect_to(post_url(reply.post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "requires notes from moderators" do
      reply = create(:reply)
      login_as(create(:admin_user))
      put :update, params: { id: reply.id }
      expect(response).to render_template(:edit)
      expect(flash[:error]).to eq('You must provide a reason for your moderator edit.')
    end

    it "stores note from moderators" do
      Reply.auditing_enabled = true
      reply = create(:reply, content: 'a')
      admin = create(:admin_user)
      login_as(admin)
      put :update, params: { id: reply.id, reply: { content: 'b', audit_comment: 'note' } }
      expect(flash[:success]).to eq("Post updated")
      expect(reply.reload.content).to eq('b')
      expect(reply.audits.last.comment).to eq('note')
      Reply.auditing_enabled = false
    end

    it "fails when invalid" do
      reply = create(:reply)
      login_as(reply.user)
      put :update, params: { id: reply.id, reply: { post_id: nil } }
      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq("Your reply could not be saved because of the following problems:")
    end

    it "succeeds" do
      user = create(:user)
      reply = create(:reply, user: user)
      newcontent = reply.content + 'new'
      login_as(user)
      char = create(:character, user: user)
      icon = create(:icon, user: user)
      calias = create(:alias, character: char)

      put :update, params: { id: reply.id, reply: {content: newcontent, character_id: char.id, icon_id: icon.id, character_alias_id: calias.id} }
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(flash[:success]).to eq("Post updated")

      reply.reload
      expect(reply.content).to eq(newcontent)
      expect(reply.character_id).to eq(char.id)
      expect(reply.icon_id).to eq(icon.id)
      expect(reply.character_alias_id).to eq(calias.id)
    end

    it "preserves reply_order" do
      reply_post = create(:post)
      login_as(reply_post.user)
      create(:reply, post: reply_post)
      reply = create(:reply, post: reply_post)
      expect(reply.reply_order).to eq(1)
      expect(reply_post.replies.ordered.last).to eq(reply)
      create(:reply, post: reply_post)
      expect(reply_post.replies.ordered.last).not_to eq(reply)
      reply_post.mark_read(reply_post.user)
      put :update, params: { id: reply.id, reply: {content: 'new content'} }
      expect(reply.reload.reply_order).to eq(1)
    end
  end
end
