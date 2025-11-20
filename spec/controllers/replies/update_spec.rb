RSpec.describe RepliesController, 'PUT update' do
  it "requires login" do
    put :update, params: { id: -1 }
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    skip "TODO Currently relies on inability to create replies"
  end

  it "requires valid reply" do
    login
    put :update, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires post access" do
    reply = create(:reply)
    reply.post.update!(privacy: :private)
    login_as(reply.user)
    put :update, params: { id: reply.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "requires reply access" do
    reply = create(:reply)
    login
    put :update, params: { id: reply.id }
    expect(response).to redirect_to(post_url(reply.post))
    expect(flash[:error]).to eq("You do not have permission to modify this reply.")
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
    expect(flash[:success]).to eq("Reply updated.")
    expect(reply.reload.content).to eq('b')
    expect(reply.audits.last.comment).to eq('note')
    Reply.auditing_enabled = false
  end

  it "does not save audit when only comment provided" do
    Reply.auditing_enabled = true
    reply = create(:reply)
    login_as(reply.user)
    expect {
      put :update, params: { id: reply.id, reply: { audit_comment: 'note' } }
    }.not_to change { Audited::Audit.count }
    Reply.auditing_enabled = false
  end

  it "fails when invalid" do
    reply = create(:reply)
    login_as(reply.user)
    put :update, params: { id: reply.id, reply: { post_id: nil } }
    expect(response).to render_template(:edit)
    expect(flash[:error][:message]).to eq("Reply could not be updated because of the following problems:")
    expect(flash[:error][:array]).to eq(["Post must exist"])
  end

  it "succeeds" do
    user = create(:user)
    reply = create(:reply, user: user)
    newcontent = reply.content + 'new'
    login_as(user)
    char = create(:character, user: user)
    icon = create(:icon, user: user)
    calias = create(:alias, character: char)

    put :update, params: { id: reply.id, reply: { content: newcontent, character_id: char.id, icon_id: icon.id, character_alias_id: calias.id } }
    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:success]).to eq("Reply updated.")

    reply.reload
    expect(reply.content).to eq(newcontent)
    expect(reply.character_id).to eq(char.id)
    expect(reply.icon_id).to eq(icon.id)
    expect(reply.character_alias_id).to eq(calias.id)
  end

  it "preserves reply_order", aggregate_failures: false do
    reply_post = create(:post)
    login_as(reply_post.user)
    create(:reply, post: reply_post)
    reply = create(:reply, post: reply_post, user: reply_post.user)

    aggregate_failures do
      expect(reply.reply_order).to eq(1)
      expect(reply_post.replies.ordered.last).to eq(reply)
    end

    create(:reply, post: reply_post)

    expect(reply_post.replies.ordered.last).not_to eq(reply)

    reply_post.mark_read(reply_post.user)

    put :update, params: { id: reply.id, reply: { content: 'new content' } }

    aggregate_failures do
      expect(flash[:success]).to eq("Reply updated.")
      expect(reply.reload.reply_order).to eq(1)
    end
  end

  it "preserves NPC" do
    user = create(:user)
    reply = create(:reply, user: user)
    login_as(user)

    expect {
      put :update, params: { id: reply.id, reply: { character_id: nil }, character: { name: 'NPC', npc: true } }
    }.to change { Character.count }.by(1)
    expect(reply.reload.character.name).to eq('NPC')
    expect(reply.reload.character.nickname).to eq(reply.post.subject)
  end

  context "preview" do
    it "takes correct actions" do
      Reply.auditing_enabled = true
      user = create(:user)
      reply_post = create(:post)
      reply = create(:reply, post: reply_post, user: user)
      login_as(user)
      expect(ReplyDraft.count).to eq(0)

      char = create(:character, user: user)
      icon = create(:icon, user: user)
      calias = create(:alias, character: char)
      char2 = create(:template_character, user: user)
      newcontent = reply.content + 'new'
      expect(controller).to receive(:build_template_groups).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original

      post :update, params: {
        id: reply.id,
        button_preview: true,
        reply: {
          content: newcontent,
          character_id: char.id,
          icon_id: icon.id,
          character_alias_id: calias.id,
        },
      }

      expect(response).to render_template(:preview)
      expect(assigns(:javascripts)).to include('posts/editor')
      expect(assigns(:page_title)).to eq(reply_post.subject)
      expect(assigns(:post)).to eq(reply_post)
      expect(assigns(:reply)).to eq(reply)
      expect(ReplyDraft.count).to eq(0)
      expect(assigns(:audits)).to eq({ reply.id => 1 })

      written = assigns(:reply)
      expect(written).not_to be_a_new_record
      expect(written.user).to eq(user)
      expect(written.character).to eq(char)
      expect(written.icon).to eq(icon)
      expect(written.character_alias).to eq(calias)

      # check it still remembers its current attributes, since this is a preview
      persisted = written.reload
      expect(persisted.user).to eq(user)
      expect(persisted.character).to be_nil
      expect(persisted.icon).to be_nil
      expect(persisted.character_alias).to be_nil

      # build_template_groups:
      expect(controller.gon.editor_user[:username]).to eq(user.username)
      # templates
      templates = assigns(:templates)
      expect(templates.length).to eq(2)
      template_chars = templates.first
      expect(template_chars).to eq(char2.template)
      templateless = templates.last
      expect(templateless.name).to eq('Templateless')
      expect(templateless.plucked_characters).to eq([[char.id, char.name]])
      Reply.auditing_enabled = false
    end

    it "preserves NPC without database" do
      user = create(:user)
      reply = create(:reply, user: user)
      login_as(user)

      # update preview doesn't create a draft, so we don't save the character in the database
      expect {
        put :update, params: {
          id: reply.id,
          button_preview: true,
          reply: { character_id: nil },
          character: { name: 'NPC', npc: true },
        }
      }.not_to change { Character.count }
      written = assigns(:reply)
      expect(written.character.name).to eq('NPC')
      expect(written.character.nickname).to eq(reply.post.subject)

      reply.reload
      expect(reply.character).to be_nil
    end

    it "takes correct actions for moderators" do
      user = create(:user)
      reply_post = create(:post, user: user)
      reply = create(:reply, post: reply_post, user: user)
      char = create(:template_character, user: user)
      login_as(create(:mod_user))

      newcontent = reply.content + 'new'

      post :update, params: {
        id: reply.id,
        button_preview: true,
        reply: {
          content: newcontent,
          audit_comment: 'note',
        },
      }

      expect(response).to render_template(:preview)
      expect(assigns(:reply).user).to eq(reply.user)
      expect(assigns(:reply).audit_comment).to eq('note')
      expect(assigns(:reply).content).to eq(newcontent)

      expect(controller.gon.editor_user[:username]).to eq(user.username)
      expect(assigns(:templates)).to eq([char.template])
    end

    skip
  end
end
