RSpec.describe DraftsController do
  describe 'POST create' do
    it "displays errors if relevant" do
      draft = create(:reply_draft)
      login_as(draft.user)
      post :create, params: { button_draft: true, reply: { post_id: '' } }
      expect(flash[:error][:message]).to eq("Draft could not be saved because of the following problems:")
      expect(draft.reload.post_id).not_to be_nil
      expect(response).to redirect_to(posts_url)
    end

    it "creates a new draft if none exists" do
      user = create(:user)
      reply_post = create(:post, user: user)
      login_as(user)
      char = create(:character, user: user)
      icon = create(:icon, user: user)
      calias = create(:alias, character: char)

      expect(ReplyDraft.count).to eq(0)
      post :create, params: {
        button_draft: true,
        reply: {
          post_id: reply_post.id,
          character_id: char.id,
          icon_id: icon.id,
          content: 'testcontent',
          character_alias_id: calias.id,
          editor_mode: 'html',
        },
      }
      expect(response).to redirect_to(post_url(reply_post, page: :unread, anchor: :unread))
      expect(flash[:success]).to eq("Draft saved.")
      expect(ReplyDraft.count).to eq(1)

      draft = ReplyDraft.last
      expect(draft.post).to eq(reply_post)
      expect(draft.user).to eq(user)
      expect(draft.character_id).to eq(char.id)
      expect(draft.icon_id).to eq(icon.id)
      expect(draft.content).to eq('testcontent')
      expect(draft.character_alias_id).to eq(calias.id)
      expect(draft.editor_mode).to eq('html')
    end

    it "preserves NPC" do
      user = create(:user)
      reply_post = create(:post, user: user)
      login_as(user)

      icon = create(:icon, user: user)

      expect {
        post :create, params: {
          button_draft: true,
          reply: {
            content: 'example',
            character_id: nil,
            icon_id: icon.id,
            post_id: reply_post.id,
            editor_mode: 'html',
          },
          character: {
            name: 'NPC',
            npc: true,
          },
        }
      }.to change { Character.count }.by(1)
      expect(response).to redirect_to(post_url(reply_post, page: :unread, anchor: :unread))
      expect(flash[:success]).to eq("Draft saved. Your new NPC character has also been persisted!")
      expect(ReplyDraft.count).to eq(1)

      draft = ReplyDraft.last
      expect(draft.character.name).to eq('NPC')
      expect(draft.character).to be_npc
      expect(draft.character.default_icon_id).to eq(icon.id)
      expect(draft.character.nickname).to eq(reply_post.subject)
    end

    it "updates the existing draft if one exists" do
      draft = create(:reply_draft)
      login_as(draft.user)
      post :create, params: {
        button_draft: true,
        reply: {
          post_id: draft.post.id,
          content: 'new draft',
          editor_mode: 'rtf',
        },
      }
      expect(flash[:success]).to eq("Draft saved.")
      expect(draft.reload.content).to eq('new draft')
      expect(draft.editor_mode).to eq('rtf')
      expect(ReplyDraft.count).to eq(1)
    end
  end

  describe 'DELETE destroy' do
    it "successfully deletes an existing draft" do
      draft = create(:reply_draft)
      login_as(draft.user)
      delete :destroy, params: { id: draft.id, reply: { post_id: draft.post_id } }
      expect(flash[:success]).to eq("Draft deleted.")
      expect(response).to redirect_to(post_path(draft.post_id, page: :unread, anchor: :unread))
      expect(ReplyDraft.find_by(id: draft.id)).to be_nil
    end

    it "handles missing draft gracefully" do
      user = create(:user)
      reply_post = create(:post)
      login_as(user)
      delete :destroy, params: { id: -1, reply: { post_id: reply_post.id } }
      expect(flash[:error][:message]).to eq("Draft could not be deleted")
      expect(response).to redirect_to(post_path(reply_post.id, page: :unread, anchor: :unread))
    end
  end
end
