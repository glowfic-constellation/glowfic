RSpec.describe RepliesController, 'POST create' do
  it "requires login" do
    post :create
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    login_as(create(:reader_user))
    post :create
    expect(response).to redirect_to(continuities_path)
    expect(flash[:error]).to eq("You do not have permission to create replies.")
  end

  context "preview" do
    it "takes correct actions" do
      user = create(:user)
      reply_post = create(:post)
      create(:reply, post: reply_post) # reply
      reply_post.mark_read(user)
      login_as(user)
      expect(ReplyDraft.count).to eq(0)

      char1 = create(:character, user: user)
      icon = create(:icon, user: user)
      calias = create(:alias, character: char1)
      char2 = create(:template_character, user: user)
      expect(controller).to receive(:build_template_groups).and_call_original
      expect(controller).to receive(:make_draft).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original

      post :create, params: {
        button_preview: true,
        reply: {
          content: 'example',
          character_id: char1.id,
          icon_id: icon.id,
          character_alias_id: calias.id,
          post_id: reply_post.id,
          editor_mode: 'html',
        },
      }
      expect(response).to render_template(:preview)
      expect(assigns(:javascripts)).to include('posts/editor')
      expect(assigns(:page_title)).to eq(reply_post.subject)
      expect(assigns(:reply)).to be_a_new_record
      expect(assigns(:reply).post).to eq(reply_post)
      expect(assigns(:reply).user).to eq(user)
      expect(assigns(:reply).content).to eq('example')
      expect(assigns(:reply).character).to eq(char1)
      expect(assigns(:reply).icon).to eq(icon)
      expect(assigns(:reply).character_alias).to eq(calias)
      expect(assigns(:post)).to eq(reply_post)
      expect(ReplyDraft.count).to eq(1)
      draft = ReplyDraft.last

      expect(draft.post).to eq(reply_post)
      expect(draft.user).to eq(user)
      expect(draft.content).to eq('example')
      expect(draft.character).to eq(char1)
      expect(draft.icon).to eq(icon)
      expect(draft.character_alias).to eq(calias)
      expect(flash[:success]).to eq('Draft saved.')

      # build_template_groups:
      expect(controller.gon.editor_user[:username]).to eq(user.username)
      # templates
      templates = assigns(:templates)
      expect(templates.length).to eq(2)
      template = templates.first
      expect(template).to eq(char2.template)
      templateless = templates.last
      expect(templateless.name).to eq('Templateless')
      expect(templateless.plucked_characters).to eq([[char1.id, char1.name]])
    end

    it "does not create authors" do
      user = create(:user)
      board = create(:board, authors_locked: true)
      reply_post = create(:post, user: board.creator, board: board)
      expect(reply_post.user.id).not_to eq(user.id)
      login_as(user)

      expect {
        post :create, params: {
          button_preview: true,
          reply: {
            content: 'example',
            post_id: reply_post.id,
          },
        }
      }.not_to change { [Post::Author.count, BoardAuthor.count] }

      expect(flash[:success]).to be_present
    end

    it "preserves NPC" do
      user = create(:user)
      reply_post = create(:post, user: user)
      login_as(user)

      icon = create(:icon, user: user)

      expect {
        post :create, params: {
          button_preview: true,
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
      expect(response).to render_template(:preview)

      expect(assigns(:reply)).to be_a_new_record
      expect(assigns(:reply).character).not_to be_a_new_record
      expect(assigns(:reply).character.name).to eq('NPC')
      expect(assigns(:reply).character).to be_npc
      expect(assigns(:reply).character.default_icon_id).to eq(icon.id)
      expect(assigns(:reply).character.nickname).to eq(reply_post.subject)
    end
  end

  it "requires valid post" do
    login
    post :create
    expect(response).to redirect_to(posts_url)
    expect(flash[:error][:message]).to eq("Reply could not be created because of the following problems:")
  end

  it "requires post read" do
    reply_post = create(:post)
    login_as(reply_post.user)
    reply_post.mark_read(reply_post.user)
    create(:reply, post: reply_post)

    post :create, params: {
      reply: {
        post_id: reply_post.id,
        content: 'new draft',
        editor_mode: 'html',
      },
    }

    expect(response.status).to eq(200)
    expect(flash[:error]).to eq("There has been 1 new reply since you last viewed this post.")
  end

  it "handles multiple creations with unread warning" do
    reply_post = create(:post)
    login_as(reply_post.user)
    reply_post.mark_read(reply_post.user)
    create(:reply, post: reply_post) # last_seen

    post :create, params: {
      reply: {
        post_id: reply_post.id,
        content: 'new draft',
        editor_mode: 'html',
      },
    }

    expect(response.status).to eq(200)
    expect(flash[:error]).to eq("There has been 1 new reply since you last viewed this post.")

    create(:reply, post: reply_post)
    create(:reply, post: reply_post)

    post :create, params: {
      reply: {
        post_id: reply_post.id,
        content: 'new draft',
        editor_mode: 'html',
      },
    }

    expect(response.status).to eq(200)
    expect(flash[:error]).to eq("There have been 2 new replies since you last viewed this post.")
  end

  it "handles multiple creations by user" do
    reply_post = create(:post)
    login_as(reply_post.user)
    dupe_reply = create(:reply, user: reply_post.user, post: reply_post)
    reply_post.mark_read(reply_post.user, at_time: dupe_reply.created_at + 1.second, force: true)

    post :create, params: {
      reply: {
        post_id: reply_post.id,
        user_id: reply_post.user_id,
        content: dupe_reply.content,
        editor_mode: 'html',
      },
    }

    expect(response).to have_http_status(200)
    expect(flash[:error]).to eq("This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional.")

    post :create, params: {
      reply: {
        post_id: reply_post.id,
        user_id: reply_post.user_id,
        content: dupe_reply.content,
        editor_mode: 'html',
      },
      allow_dupe: true,
    }

    expect(response).to have_http_status(302)
    expect(flash[:success]).to eq("Reply posted.")
  end

  it "handles duplicate with other unseen replies" do
    reply_post = create(:post)
    login_as(reply_post.user)
    reply_post.mark_read(reply_post.user)
    create(:reply, post: reply_post)
    dupe_reply = create(:reply, user: reply_post.user, post: reply_post)

    expect {
      post :create, params: { reply: { post_id: reply_post.id, user_id: reply_post.user_id, content: dupe_reply.content } }
    }.to change { ReplyDraft.count }.by(1)
    expect(response).to have_http_status(200)
    expect(flash[:error]).to eq("This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional.")
  end

  it "requires valid params if read" do
    user = create(:user)
    login_as(user)
    character = create(:character)
    reply_post = create(:post)
    reply_post.mark_read(user, at_time: reply_post.created_at + 1.second, force: true)

    post :create, params: {
      reply: {
        post_id: reply_post.id,
        character_id: character.id,
        editor_mode: 'html',
      },
    }

    expect(response).to redirect_to(post_url(reply_post))
    expect(flash[:error][:message]).to eq("Reply could not be created because of the following problems:")
  end

  it "saves a new reply successfully if read" do
    user = create(:user)
    login_as(user)
    reply_post = create(:post)
    reply_post.mark_read(user, at_time: reply_post.created_at + 1.second, force: true)
    char = create(:character, user: user)
    icon = create(:icon, user: user)
    calias = create(:alias, character: char)

    expect {
      post :create, params: {
        reply: {
          post_id: reply_post.id,
          content: 'test!',
          character_id: char.id,
          icon_id: icon.id,
          character_alias_id: calias.id,
          editor_mode: 'html',
        },
      }
    }.to change { Reply.count }.by(1)

    reply = Reply.order(:id).last
    expect(reply).not_to be_nil
    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:success]).to eq("Reply posted.")
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
    reply_post.mark_read(user, at_time: reply_post.created_at + 1.second, force: true)

    expect {
      post :create, params: {
        reply: {
          post_id: reply_post.id,
          content: 'test content!',
          editor_mode: 'html',
        },
      }
    }.to change { Reply.count }.by(1)

    reply = Reply.order(:id).last
    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(reply).not_to be_nil
    expect(flash[:success]).to eq('Reply posted.')
    expect(reply.user).to eq(user)
    expect(reply.content).to eq('test content!')
  end

  it "allows you to reply to join a post you did not create" do
    user = create(:user)
    login_as(user)
    reply_post = create(:post)
    reply_post.mark_read(user, at_time: reply_post.created_at + 1.second, force: true)

    expect {
      post :create, params: {
        reply: {
          post_id: reply_post.id,
          content: 'test content again!',
          editor_mode: 'html',
        },
      }
    }.to change { Reply.count }.by(1)

    reply = Reply.order(:id).last
    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(reply).not_to be_nil
    expect(flash[:success]).to eq('Reply posted.')
    expect(reply.user).to eq(user)
    expect(reply.content).to eq('test content again!')
  end

  it "allows you to reply to a post you already joined" do
    user = create(:user)
    login_as(user)
    reply_post = create(:post)
    reply_old = create(:reply, post: reply_post, user: user)
    reply_post.mark_read(user, at_time: reply_old.created_at + 1.second, force: true)

    expect {
      post :create, params: { reply: { post_id: reply_post.id, content: 'test content the third!' } }
    }.to change { Reply.count }.by(1)

    reply = Reply.ordered.last
    expect(reply).not_to eq(reply_old)
    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:success]).to eq('Reply posted.')
    expect(reply.user).to eq(user)
    expect(reply.content).to eq('test content the third!')
  end

  it "allows you to reply to a closed post you already joined" do
    user = create(:user)
    login_as(user)
    reply_post = create(:post)
    reply_old = create(:reply, post: reply_post, user: user)
    reply_post.mark_read(user, at_time: reply_old.created_at + 1.second, force: true)
    reply_post.update!(authors_locked: true)

    expect {
      post :create, params: {
        reply: {
          post_id: reply_post.id,
          content: 'test content the third!',
          editor_mode: 'html',
        },
      }
    }.to change { Reply.count }.by(1)

    reply = Reply.order(id: :desc).first
    expect(reply).not_to eq(reply_old)
    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:success]).to eq('Reply posted.')
    expect(reply.user).to eq(user)
    expect(reply.content).to eq('test content the third!')
  end

  it "allows replies from authors in a closed post" do
    user = create(:user)
    other_user = create(:user)
    login_as(user)
    reply_post = create(:post, user: other_user, tagging_authors: [user, other_user], authors_locked: true)
    reply_post.mark_read(user)

    expect {
      post :create, params: {
        reply: {
          post_id: reply_post.id,
          content: 'test content!',
          editor_mode: 'html',
        },
      }
    }.to change { Reply.count }.by(1)
  end

  it "allows replies from owner in a closed post" do
    user = create(:user)
    other_user = create(:user)
    login_as(user)
    other_post = create(:post, user: user, tagging_authors: [user, other_user], authors_locked: true)
    other_post.mark_read(user)
    expect {
      post :create, params: {
        reply: {
          post_id: other_post.id,
          content: 'more test content!',
          editor_mode: 'html',
        },
      }
    }.to change { Reply.count }.by(1)
  end

  it "adds authors correctly when a user replies to an open thread" do
    user = create(:user)
    login_as(user)
    reply_post = create(:post)
    reply_post.mark_read(user)

    expect {
      Timecop.freeze(Time.zone.now) do
        post :create, params: {
          reply: {
            post_id: reply_post.id,
            content: 'test content!',
            editor_mode: 'html',
          },
        }
      end
    }.to change { Reply.count }.by(1)

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
    reply_post.mark_read(user, at_time: old_reply.created_at + 1.second, force: true)

    expect {
      post :create, params: {
        reply: {
          post_id: reply_post.id,
          content: 'test content!',
          editor_mode: 'html',
        },
      }
    }.to change { Reply.count }.by(1)

    expect(reply_post.tagging_authors).to match_array([user, reply_post.user])
  end

  it "handles trying to reply to a closed thread as a non-author correctly" do
    user = create(:user)
    login_as(user)
    reply_post = create(:post, authors_locked: true)
    reply_post.mark_read(user)

    post :create, params: {
      reply: {
        post_id: reply_post.id,
        content: 'test',
        editor_mode: 'html',
      },
    }

    expect(flash[:error][:message]).to eq("Reply could not be created because of the following problems:")
    expect(flash[:error][:array]).to eq(["User #{user.username} cannot write in this post"])
  end

  it "sets reply_order correctly on the first reply" do
    reply_post = create(:post)
    login_as(reply_post.user)
    reply_post.mark_read(reply_post.user)
    searchable = 'searchable content'

    post :create, params: {
      reply: {
        post_id: reply_post.id,
        content: searchable,
        editor_mode: 'html',
      },
    }

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

    post :create, params: {
      reply: {
        post_id: reply_post.id,
        content: searchable,
        editor_mode: 'html',
      },
    }

    reply = reply_post.replies.ordered.last
    expect(reply.content).to eq(searchable)
    expect(reply.reply_order).to eq(1)
  end

  context "multi-reply" do
    it "discards multi-reply for new post" do
      user = create(:user)
      reply_post = create(:post, user: user)
      login_as(user)
      reply_post.mark_read(user)

      post :create, params: {
        button_discard_multi_reply: true,
        reply: { post_id: reply_post.id, content: 'discarded' },
      }
      expect(flash[:success]).to eq("Replies discarded.")
      expect(response).to redirect_to(post_path(reply_post.id, page: :unread, anchor: :unread))
    end

    it "adds a reply to the multi-reply list" do
      user = create(:user)
      reply_post = create(:post, user: user)
      login_as(user)
      reply_post.mark_read(user)

      post :create, params: {
        button_add_more: true,
        reply: { post_id: reply_post.id, content: 'first reply', editor_mode: 'html' },
      }
      expect(response).to render_template(:preview)
      expect(assigns(:adding_to_multi_reply)).to be true
    end

    it "submits previewed multi-reply" do
      user = create(:user)
      reply_post = create(:post, user: user)
      login_as(user)
      reply_post.mark_read(user)

      multi_replies = [
        { post_id: reply_post.id, content: 'multi reply 1', editor_mode: 'html' },
        { post_id: reply_post.id, content: 'multi reply 2', editor_mode: 'html' },
      ].to_json
      expect {
        post :create, params: {
          button_submit_previewed_multi_reply: true,
          reply: { post_id: reply_post.id },
          multi_replies_json: multi_replies,
        }
      }.to change { Reply.count }.by(2)
      expect(flash[:success]).to eq("Replies posted.")
    end

    it "submits single previewed multi-reply" do
      user = create(:user)
      reply_post = create(:post, user: user)
      login_as(user)
      reply_post.mark_read(user)

      multi_replies = [{ post_id: reply_post.id, content: 'only reply', editor_mode: 'html' }].to_json
      expect {
        post :create, params: {
          button_submit_previewed_multi_reply: true,
          reply: { post_id: reply_post.id },
          multi_replies_json: multi_replies,
        }
      }.to change { Reply.count }.by(1)
      expect(flash[:success]).to eq("Reply posted.")
    end
  end

  it "sets reply_order correctly with multiple existing replies" do
    reply_post = create(:post)
    login_as(reply_post.user)
    create(:reply, post: reply_post)
    create(:reply, post: reply_post)
    reply_post.mark_read(reply_post.user)
    searchable = 'searchable content'

    post :create, params: {
      reply: {
        post_id: reply_post.id,
        content: searchable,
        editor_mode: 'html',
      },
    }

    reply = reply_post.replies.ordered.last
    expect(reply.content).to eq(searchable)
    expect(reply.reply_order).to eq(2)
  end
end
