RSpec.describe Api::V1::PostsController do
  describe "GET index" do
    shared_examples_for "index.parsed_body" do |in_doc|
      it "should support no search", show_in_doc: in_doc do
        post = create(:post)
        get :index, params: { min: 'true' }
        expect(response).to have_http_status(200)
        expect(response.parsed_body).to have_key('results')
        expect(response.parsed_body['results']).to contain_exactly(post.as_json(min: true).stringify_keys)
      end

      it "should support search", show_in_doc: in_doc do
        post = create(:post, subject: 'search')
        create(:post, subject: 'no') # post2
        get :index, params: { q: 'se', min: 'true' }
        expect(response).to have_http_status(200)
        expect(response.parsed_body).to have_key('results')
        expect(response.parsed_body['results'].count).to eq(1)
        expect(response.parsed_body['results']).to contain_exactly(post.as_json(min: true).stringify_keys)
      end

      it "hides private posts" do
        create(:post, privacy: :private)
        post = create(:post)
        get :index, params: { min: 'true' }
        expect(response).to have_http_status(200)
        expect(response.parsed_body).to have_key('results')
        expect(response.parsed_body['results'].count).to eq(1)
        expect(response.parsed_body['results']).to contain_exactly(post.as_json(min: true).stringify_keys)
      end

      it "supports full response", show_in_doc: in_doc do
        post = create(:post)
        get :index
        expect(response).to have_http_status(200)
        expect(response.parsed_body).to have_key('results')
        post_response = response.parsed_body['results'].first
        expect(post_response['id']).to eq(post.id)
        expect(post_response['subject']).to eq(post.subject)
        expect(post_response['tagged_at']).to be_the_same_time_as(post.tagged_at)
        expect(post_response['authors']).to eq(post.joined_authors.ordered.map { |a| a.as_json.stringify_keys })
        expect(post_response['num_replies']).to eq(post.reply_count)
      end
    end

    context "when logged in" do
      before(:each) { api_login }

      it_behaves_like "index.parsed_body", false
    end

    context "when logged out" do
      it_behaves_like "index.parsed_body", true
    end
  end

  describe "GET show" do
    it "requires valid post", :show_in_doc do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Post could not be found.")
    end

    it "requires access to post", :show_in_doc do
      post = create(:post, privacy: :private)
      get :show, params: { id: post.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "succeeds with valid post", :show_in_doc do
      post = create(:post, with_icon: true, with_character: true)
      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(post.id)
      expect(response.parsed_body['num_replies']).to eq(0)
      expect(response.parsed_body['authors'].size).to eq(1)
      expect(response.parsed_body['authors'][0]['id']).to eq(post.user_id)
      expect(response.parsed_body['content']).to eq(post.content)
      expect(response.parsed_body['icon']['id']).to eq(post.icon_id)
      expect(response.parsed_body['character']['id']).to eq(post.character_id)
    end
  end

  describe "PATCH update" do
    it "requires login", :show_in_doc do
      patch :update, params: { id: 0 }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires valid post", :show_in_doc do
      api_login
      patch :update, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Post could not be found.")
    end

    it "requires access to post", :show_in_doc do
      api_login
      post = create(:post, privacy: :private)
      patch :update, params: { id: post.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "requires private_note param", :show_in_doc do
      api_login
      post = create(:post)
      patch :update, params: { id: post.id }
      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq("Missing parameter private_note")
    end

    it "requires authorship of post" do
      api_login
      post = create(:post)
      patch :update, params: { id: post.id, private_note: "Shiny new note" }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "handles failed saves" do
      user = api_login
      post = create(:post, user: user)
      author = post.author_for(user)

      allow(Post).to receive(:find_by).and_call_original
      allow(Post).to receive(:find_by).with({ id: post.id.to_s }).and_return(post)
      allow(post).to receive(:author_for).with(user).and_return(author)
      allow(author).to receive(:update).and_return(false)
      expect(author).to receive(:update)

      patch :update, params: { id: post.id, private_note: 'Shiny new note' }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq('Post could not be updated.')
    end

    it "succeeds with valid post", :show_in_doc do
      user = api_login
      post = create(:post, user: user)
      expect(post.author_for(user).private_note).to be_nil

      patch :update, params: { id: post.id, private_note: 'Shiny new note' }

      expect(response).to have_http_status(200)
      expect(response.parsed_body['private_note']).to eq("<p>Shiny new note</p>")
      expect(post.author_for(user).private_note).to eq('Shiny new note')
    end

    it "allows empty notes to blank them out", :show_in_doc do
      user = api_login
      post = create(:post, user: user)
      post.author_for(user).update!(private_note: "some text here")

      patch :update, params: { id: post.id, private_note: '' }

      expect(response).to have_http_status(200)
      expect(response.parsed_body['private_note']).to eq("")
      expect(post.author_for(user).private_note).to eq('')
    end
  end

  describe "POST reorder" do
    it "requires login", :show_in_doc do
      post :reorder
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    context "without section_id" do
      it "requires a board you have access to" do
        board = create(:board)
        board_post1 = create(:post, board_id: board.id)
        board_post2 = create(:post, board_id: board.id)
        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)

        post_ids = [board_post2.id, board_post1.id]

        api_login
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(403)
        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)
      end

      it "requires a single board without section_id" do
        user = create(:user)
        board1 = create(:board, creator: user)
        board2 = create(:board, creator: user)
        board_post1 = create(:post, board_id: board1.id)
        board_post2 = create(:post, board_id: board2.id)
        board_post3 = create(:post, board_id: board2.id)

        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(0)
        expect(board_post3.reload.section_order).to eq(1)

        post_ids = [board_post3.id, board_post2.id, board_post1.id]
        api_login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to eq('Posts must be from one continuity')
        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(0)
        expect(board_post3.reload.section_order).to eq(1)
      end

      it "requires section_id if posts in section" do
        user = create(:user)
        board = create(:board, creator: user)
        section = create(:board_section, board_id: board.id)
        board_post1 = create(:post, board_id: board.id, section_id: section.id)
        board_post2 = create(:post, board_id: board.id, section_id: section.id)

        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)

        post_ids = [board_post2.id, board_post1.id]
        api_login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to eq('Posts must be from one specified section in the continuity, or no section')
        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)
      end

      it "requires valid post_ids" do
        user = create(:user)
        board = create(:board, creator: user)
        post1 = create(:post, board_id: board.id)
        post2 = create(:post, board_id: board.id)
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [-1]
        api_login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(404)
        expect(response.parsed_body['errors'][0]['message']).to eq('Some posts could not be found: -1')
      end

      it "works for valid changes", :show_in_doc do
        board = create(:board)
        board2 = create(:board, creator: board.creator)
        board_post1 = create(:post, board_id: board.id)
        board_post2 = create(:post, board_id: board.id)
        board_post3 = create(:post, board_id: board.id)
        board_post4 = create(:post, board_id: board.id)
        board_post5 = create(:post, board_id: board2.id)

        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)
        expect(board_post3.reload.section_order).to eq(2)
        expect(board_post4.reload.section_order).to eq(3)
        expect(board_post5.reload.section_order).to eq(0)

        post_ids = [board_post3.id, board_post1.id, board_post4.id, board_post2.id]

        api_login_as(board.creator)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(200)
        expect(response.parsed_body).to eq({ 'post_ids' => post_ids })
        expect(board_post1.reload.section_order).to eq(1)
        expect(board_post2.reload.section_order).to eq(3)
        expect(board_post3.reload.section_order).to eq(0)
        expect(board_post4.reload.section_order).to eq(2)
        expect(board_post5.reload.section_order).to eq(0)
      end

      it "works when specifying valid subset", :show_in_doc do
        board = create(:board)
        board2 = create(:board, creator: board.creator)
        board_post1 = create(:post, board_id: board.id)
        board_post2 = create(:post, board_id: board.id)
        board_post3 = create(:post, board_id: board.id)
        board_post4 = create(:post, board_id: board.id)
        board_post5 = create(:post, board_id: board2.id)

        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)
        expect(board_post3.reload.section_order).to eq(2)
        expect(board_post4.reload.section_order).to eq(3)
        expect(board_post5.reload.section_order).to eq(0)

        post_ids = [board_post3.id, board_post1.id]

        api_login_as(board.creator)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(200)
        expect(response.parsed_body).to eq({ 'post_ids' => [board_post3.id, board_post1.id, board_post2.id, board_post4.id] })
        expect(board_post1.reload.section_order).to eq(1)
        expect(board_post2.reload.section_order).to eq(2)
        expect(board_post3.reload.section_order).to eq(0)
        expect(board_post4.reload.section_order).to eq(3)
        expect(board_post5.reload.section_order).to eq(0)
      end
    end

    context "with section_id" do
      it "requires a board you have access to" do
        board = create(:board)
        section = create(:board_section, board_id: board.id)
        board_post1 = create(:post, board_id: board.id, section_id: section.id)
        board_post2 = create(:post, board_id: board.id, section_id: section.id)
        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)

        post_ids = [board_post2.id, board_post1.id]

        api_login
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(403)
        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)
      end

      it "requires a single section" do
        user = create(:user)
        board = create(:board, creator: user)
        board_section1 = create(:board_section, board_id: board.id)
        board_section2 = create(:board_section, board_id: board.id)
        board_post1 = create(:post, board_id: board.id, section_id: board_section1.id)
        board_post2 = create(:post, board_id: board.id, section_id: board_section2.id)
        board_post3 = create(:post, board_id: board.id, section_id: board_section2.id)

        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(0)
        expect(board_post3.reload.section_order).to eq(1)

        post_ids = [board_post3.id, board_post2.id, board_post1.id]
        api_login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: board_section1.id }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to eq('Posts must be from one specified section in the continuity, or no section')
        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(0)
        expect(board_post3.reload.section_order).to eq(1)
      end

      it "requires valid section id" do
        user = create(:user)
        board = create(:board, creator: user)
        section = create(:board_section, board_id: board.id)
        board_post1 = create(:post, board_id: board.id, section_id: section.id)
        board_post2 = create(:post, board_id: board.id, section_id: section.id)

        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)

        post_ids = [board_post2.id, board_post1.id]
        api_login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: 0 }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to eq('Posts must be from one specified section in the continuity, or no section')
        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)
      end

      it "requires correct section id" do
        user = create(:user)
        board = create(:board, creator: user)
        board_section1 = create(:board_section, board_id: board.id)
        board_section2 = create(:board_section, board_id: board.id)
        board_post1 = create(:post, board_id: board.id, section_id: board_section1.id)
        board_post2 = create(:post, board_id: board.id, section_id: board_section2.id)
        board_post3 = create(:post, board_id: board.id, section_id: board_section2.id)

        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(0)
        expect(board_post3.reload.section_order).to eq(1)

        post_ids = [board_post3.id, board_post2.id]
        api_login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: board_section1.id }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to eq('Posts must be from one specified section in the continuity, or no section')
        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(0)
        expect(board_post3.reload.section_order).to eq(1)
      end

      it "requires no section_id if posts not in section" do
        user = create(:user)
        board = create(:board, creator: user)
        section = create(:board_section, board_id: board.id)
        board_post1 = create(:post, board_id: board.id)
        board_post2 = create(:post, board_id: board.id)

        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)

        post_ids = [board_post2.id, board_post1.id]
        api_login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to eq('Posts must be from one specified section in the continuity, or no section')
        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)
      end

      it "requires valid post_ids" do
        user = create(:user)
        board = create(:board, creator: user)
        section = create(:board_section, board_id: board.id)
        post1 = create(:post, board_id: board.id, section_id: section.id)
        post2 = create(:post, board_id: board.id, section_id: section.id)
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [-1]
        api_login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(404)
        expect(response.parsed_body['errors'][0]['message']).to eq('Some posts could not be found: -1')
      end

      it "works for valid changes", :show_in_doc do
        board = create(:board)
        section = create(:board_section, board_id: board.id)
        section2 = create(:board_section, board_id: board.id)
        board_post1 = create(:post, board_id: board.id, section_id: section.id)
        board_post2 = create(:post, board_id: board.id, section_id: section.id)
        board_post3 = create(:post, board_id: board.id, section_id: section.id)
        board_post4 = create(:post, board_id: board.id, section_id: section.id)
        board_post5 = create(:post, board_id: board.id, section_id: section2.id)

        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)
        expect(board_post3.reload.section_order).to eq(2)
        expect(board_post4.reload.section_order).to eq(3)
        expect(board_post5.reload.section_order).to eq(0)

        post_ids = [board_post3.id, board_post1.id, board_post4.id, board_post2.id]

        api_login_as(board.creator)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(200)
        expect(response.parsed_body).to eq({ 'post_ids' => post_ids })
        expect(board_post1.reload.section_order).to eq(1)
        expect(board_post2.reload.section_order).to eq(3)
        expect(board_post3.reload.section_order).to eq(0)
        expect(board_post4.reload.section_order).to eq(2)
        expect(board_post5.reload.section_order).to eq(0)
      end

      it "works when specifying valid subset", :show_in_doc do
        board = create(:board)
        section = create(:board_section, board_id: board.id)
        section2 = create(:board_section, board_id: board.id)
        board_post1 = create(:post, board_id: board.id, section_id: section.id)
        board_post2 = create(:post, board_id: board.id, section_id: section.id)
        board_post3 = create(:post, board_id: board.id, section_id: section.id)
        board_post4 = create(:post, board_id: board.id, section_id: section.id)
        board_post5 = create(:post, board_id: board.id, section_id: section2.id)

        expect(board_post1.reload.section_order).to eq(0)
        expect(board_post2.reload.section_order).to eq(1)
        expect(board_post3.reload.section_order).to eq(2)
        expect(board_post4.reload.section_order).to eq(3)
        expect(board_post5.reload.section_order).to eq(0)

        post_ids = [board_post3.id, board_post1.id]

        api_login_as(board.creator)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(200)
        expect(response.parsed_body).to eq({ 'post_ids' => [board_post3.id, board_post1.id, board_post2.id, board_post4.id] })
        expect(board_post1.reload.section_order).to eq(1)
        expect(board_post2.reload.section_order).to eq(2)
        expect(board_post3.reload.section_order).to eq(0)
        expect(board_post4.reload.section_order).to eq(3)
        expect(board_post5.reload.section_order).to eq(0)
      end
    end
  end
end
