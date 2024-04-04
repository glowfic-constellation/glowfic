RSpec.describe RepliesController, 'GET search' do
  context "no search" do
    before(:each) do
      2.times do
        create(:user)
        create(:character)
        create(:template_character)
      end
    end

    it "works logged out" do
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Search Replies')
      expect(assigns(:post)).to be_nil
      expect(assigns(:search_results)).to be_nil
      expect(assigns(:users)).to be_nil # this will be dynamically loaded
      expect(assigns(:characters)).to be_nil # this will be dynamically loaded
      expect(assigns(:users)).to be_nil # this will be dynamically loaded
      expect(assigns(:templates).size).to eq(2) # this will be dynamically loaded
    end

    it "works logged in" do
      login
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Search Replies')
      expect(assigns(:post)).to be_nil
      expect(assigns(:search_results)).to be_nil
    end

    it "works for reader account" do
      login_as(create(:reader_user))
      get :search
      expect(response).to have_http_status(200)
    end

    it "sets templates by author" do
      author = create(:user)
      template = create(:template, user: author)
      create(:template)
      get :search, params: { commit: true, author_id: author.id }
      expect(assigns(:templates)).to eq([template])
    end

    it "handles invalid post" do
      get :search, params: { post_id: -1 }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Search Replies')
      expect(assigns(:post)).to be_nil
      expect(assigns(:search_results)).to be_nil
    end

    it "handles valid post" do
      templateless_char = Character.where(template_id: nil).first
      post = create(:post, character: templateless_char, user: templateless_char.user)
      create(:reply, post: post)
      user_ignoring_tags = create(:user)
      create(:reply, post: post, user: user_ignoring_tags)
      post.opt_out_of_owed(user_ignoring_tags)

      get :search, params: { post_id: post.id }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Search Replies')
      expect(assigns(:post)).to eq(post)
      expect(assigns(:search_results)).to be_nil
      expect(assigns(:users)).to match_array(post.joined_authors)
      expect(assigns(:characters)).to match_array([post.character])
      expect(assigns(:templates)).to be_empty
    end

    it "sorts templates" do
      user = create(:user)
      login_as(user)
      template3 = create(:template, user: user, name: "c")
      template1 = create(:template, user: user, name: "a")
      template2 = create(:template, user: user, name: "b")
      get :search, params: { commit: true, author_id: user.id }
      expect(assigns(:templates)).to eq([template1, template2, template3])
    end

    it "sorts characters and templates when a post is given" do
      user = create(:user)
      login_as(user)
      template3 = create(:template, user: user, name: "c")
      template1 = create(:template, user: user, name: "a")
      template2 = create(:template, user: user, name: "b")
      char3 = create(:character, template: template3, user: user, name: "c")
      char1 = create(:character, template: template1, user: user, name: "a")
      char2 = create(:character, template: template2, user: user, name: "b")
      post = create(:post, user: user, character: char2)
      create(:reply, user: user, post: post, character: char1)
      create(:reply, user: user, post: post, character: char3)
      get :search, params: { post_id: post.id }
      expect(assigns(:templates)).to eq([template1, template2, template3])
      expect(assigns(:characters)).to eq([char1, char2, char3])
    end
  end

  context "searching" do
    it "only shows from visible posts" do
      reply1 = create(:reply, content: 'contains forks')
      reply2 = create(:reply, content: 'visible contains forks')
      reply1.post.update!(privacy: :private)
      expect(reply1.post.reload).not_to be_visible_to(nil) # logged out, not visible
      expect(reply2.post.reload).to be_visible_to(nil)
      get :search, params: { commit: true, subj_content: 'forks' }
      expect(assigns(:search_results)).to match_array([reply2])
    end

    it "requires visible post if given" do
      reply1 = create(:reply)
      reply1.post.update!(privacy: :private)
      expect(reply1.post.reload).not_to be_visible_to(nil)
      get :search, params: { commit: true, post_id: reply1.post_id }
      expect(assigns(:search_results)).to be_nil
      expect(flash[:error]).to eq('You do not have permission to view this post.')
    end

    it "does not include audits" do
      Reply.auditing_enabled = true
      user = create(:user)

      replies = Audited.audit_class.as_user(user) do
        create_list(:reply, 6, user: user)
      end

      Audited.audit_class.as_user(user) do
        replies[1].touch # rubocop:disable Rails/SkipsModelValidations
        replies[3].update!(character: create(:character, user: user))
        replies[2].update!(content: 'new content')
        1.upto(5) { |i| replies[4].update!(content: 'message' + i.to_s) }
      end
      Audited.audit_class.as_user(create(:mod_user)) do
        replies[5].update!(content: 'new content')
      end

      get :search, params: { commit: true, sort: 'created_old' }
      expect(assigns(:audits)).to be_empty
      Reply.auditing_enabled = false
    end
  end
end
