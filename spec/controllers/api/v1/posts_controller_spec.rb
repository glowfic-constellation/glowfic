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

    context "with filters" do
      let(:result_ids) { response.parsed_body['results'].pluck('id') }

      it "filters by author", :show_in_doc do
        author = create(:user)
        own_post = create(:post, user: author)
        coauthored = create(:post, unjoined_authors: [author])
        create(:post)
        get :index, params: { author_id: author.id, min: 'true' }
        expect(response).to have_http_status(200)
        expect(result_ids).to contain_exactly(own_post.id, coauthored.id)
      end

      it "filters by continuity", :show_in_doc do
        board = create(:board)
        board_post = create(:post, board: board)
        create(:post)
        get :index, params: { board_id: board.id, min: 'true' }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq([board_post.id])
      end

      it "filters by character in post or replies", :show_in_doc do
        character = create(:character)
        post_with_char = create(:post, user: character.user, character: character)
        reply_with_char = create(:reply, user: character.user, character: character).post
        create(:reply, with_character: true)
        create(:post, with_character: true)
        get :index, params: { character_id: character.id, min: 'true' }
        expect(response).to have_http_status(200)
        expect(result_ids).to contain_exactly(post_with_char.id, reply_with_char.id)
      end

      it "filters by template" do
        template = create(:template)
        char1 = create(:character, template: template, user: template.user)
        char2 = create(:character, template: template, user: template.user)
        post1 = create(:post, user: template.user, character: char1)
        post2 = create(:reply, user: template.user, character: char2).post
        create(:post, with_character: true)
        get :index, params: { template_id: template.id, min: 'true' }
        expect(response).to have_http_status(200)
        expect(result_ids).to contain_exactly(post1.id, post2.id)
      end

      it "filters by status", :show_in_doc do
        complete = create(:post, status: :complete)
        create(:post, status: :active)
        create(:post, status: :hiatus)
        get :index, params: { status: 'complete', min: 'true' }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq([complete.id])
      end

      it "combines filters" do
        author = create(:user)
        board = create(:board)
        character = create(:character, user: author)
        match = create(:post, user: author, board: board, character: character, subject: 'match', status: :complete)
        create(:post, user: author, board: board, character: character, subject: 'match') # wrong status
        create(:post, user: author, board: board, subject: 'match', status: :complete) # no character
        create(:post, user: author, character: character, subject: 'match', status: :complete) # wrong board
        create(:post, board: board, subject: 'match', status: :complete) # wrong author
        create(:post, user: author, board: board, character: character, subject: 'other', status: :complete) # wrong subject
        get :index, params: { author_id: author.id, board_id: board.id, character_id: character.id, status: 'complete', q: 'mat' }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq([match.id])
      end

      it "orders by subject by default" do
        post_b = create(:post, subject: 'b')
        post_a = create(:post, subject: 'A')
        post_c = create(:post, subject: 'c')
        get :index, params: { min: 'true' }
        expect(result_ids).to eq([post_a.id, post_b.id, post_c.id])
      end

      it "orders by tagged_at", :show_in_doc do
        post_a = create(:post, subject: 'a')
        post_b = create(:post, subject: 'b')
        post_c = create(:post, subject: 'c')
        post_a.update_columns(tagged_at: 1.hour.ago) # rubocop:disable Rails/SkipsModelValidations
        post_b.update_columns(tagged_at: 3.hours.ago) # rubocop:disable Rails/SkipsModelValidations
        post_c.update_columns(tagged_at: 2.hours.ago) # rubocop:disable Rails/SkipsModelValidations
        get :index, params: { order: 'tagged_at', min: 'true' }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq([post_a.id, post_c.id, post_b.id])
      end

      context "with invalid parameters" do
        it "rejects non-numeric IDs", :show_in_doc do
          get :index, params: { author_id: 'abc' }
          expect(response).to have_http_status(422)
          expect(response.parsed_body['errors'][0]['message']).to include('author_id')
        end

        it "rejects missing users", :show_in_doc do
          get :index, params: { author_id: 0 }
          expect(response).to have_http_status(422)
          expect(response.parsed_body['errors'][0]['message']).to eq('User could not be found.')
        end

        it "rejects missing continuities" do
          get :index, params: { board_id: 0 }
          expect(response).to have_http_status(422)
          expect(response.parsed_body['errors'][0]['message']).to eq('Board could not be found.')
        end

        it "rejects missing characters" do
          get :index, params: { character_id: 0 }
          expect(response).to have_http_status(422)
          expect(response.parsed_body['errors'][0]['message']).to eq('Character could not be found.')
        end

        it "rejects missing templates" do
          get :index, params: { template_id: 0 }
          expect(response).to have_http_status(422)
          expect(response.parsed_body['errors'][0]['message']).to eq('Template could not be found.')
        end

        it "rejects unknown statuses" do
          get :index, params: { status: 'finished' }
          expect(response).to have_http_status(422)
          expect(response.parsed_body['errors'][0]['message']).to include('status')
        end

        it "rejects unknown orders" do
          get :index, params: { order: 'created_at' }
          expect(response).to have_http_status(422)
          expect(response.parsed_body['errors'][0]['message']).to include('order')
        end

        it "rejects non-boolean owed" do
          get :index, params: { owed: 'maybe' }
          expect(response).to have_http_status(422)
          expect(response.parsed_body['errors'][0]['message']).to include('owed')
        end
      end

      context "with privacy" do
        let(:author) { create(:user) }
        let!(:public_post) { create(:post, user: author) }

        before(:each) do
          create(:post, user: author, privacy: :private)
          create(:post, user: author, privacy: :registered)
          create(:post, user: author, privacy: :access_list)
        end

        it "only shows public posts when logged out" do
          get :index, params: { author_id: author.id }
          expect(result_ids).to eq([public_post.id])
          expect(response.headers['Total'].to_i).to eq(1)
        end

        it "hides private and inaccessible posts from other users" do
          api_login
          get :index, params: { author_id: author.id }
          expect(result_ids).to match_array([public_post.id, Post.privacy_registered.first.id])
          expect(response.headers['Total'].to_i).to eq(2)
        end

        it "shows access-listed posts to viewers" do
          viewer = api_login
          access_post = Post.privacy_access_list.first
          PostViewer.create!(post: access_post, user: viewer)
          get :index, params: { author_id: author.id }
          expect(result_ids).to match_array([public_post.id, Post.privacy_registered.first.id, access_post.id])
        end

        it "shows all posts to the author" do
          api_login_as(author)
          get :index, params: { author_id: author.id }
          expect(response.headers['Total'].to_i).to eq(4)
        end
      end

      context "with owed" do
        let(:user) { create(:user) }
        let(:other_user) { create(:user) }
        let!(:owed_post) { create(:post, user: user, unjoined_authors: [other_user], subject: 'owed') }

        before(:each) { create(:reply, post: owed_post, user: other_user) }

        it "requires login", :show_in_doc do
          get :index, params: { owed: true }
          expect(response).to have_http_status(401)
          expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged in to view that page.")
        end

        it "ignores owed=false when logged out" do
          get :index, params: { owed: false, min: 'true' }
          expect(response).to have_http_status(200)
          expect(result_ids).to eq([owed_post.id])
        end

        it "returns posts the user owes a reply on", :show_in_doc do
          api_login_as(user)
          replied = create(:post, user: user, unjoined_authors: [other_user])
          create(:reply, post: replied, user: user)
          create(:post, user: other_user) # not an author
          get :index, params: { owed: true }
          expect(response).to have_http_status(200)
          expect(result_ids).to eq([owed_post.id])
        end

        it "includes posts with drafts" do
          api_login_as(user)
          drafted = create(:post, user: user, unjoined_authors: [other_user])
          create(:reply, post: drafted, user: other_user)
          create(:reply, post: drafted, user: user)
          create(:reply_draft, post: drafted, user: user)
          get :index, params: { owed: true }
          expect(result_ids).to contain_exactly(owed_post.id, drafted.id)
        end

        it "excludes completed, abandoned and opted-out posts" do
          api_login_as(user)
          [:complete, :abandoned].each do |status|
            post = create(:post, user: user, unjoined_authors: [other_user], status: status)
            create(:reply, post: post, user: other_user)
          end
          opted_out = create(:post, user: user, unjoined_authors: [other_user])
          create(:reply, post: opted_out, user: other_user)
          opted_out.opt_out_of_owed(user)
          get :index, params: { owed: true }
          expect(result_ids).to eq([owed_post.id])
        end

        it "excludes site testing posts" do
          api_login_as(user)
          owed_post.update!(board: create(:board, id: Board::ID_SITETESTING))
          get :index, params: { owed: true }
          expect(result_ids).to be_empty
        end

        context "with hiatused posts" do
          let!(:hiatused) { create(:post, user: user, unjoined_authors: [other_user]) }

          before(:each) do
            create(:reply, post: hiatused, user: other_user)
            hiatused.update!(status: :hiatus)
          end

          it "includes hiatused posts by default" do
            api_login_as(user)
            get :index, params: { owed: true }
            expect(result_ids).to contain_exactly(owed_post.id, hiatused.id)
          end

          it "respects the hide hiatused preference" do
            user.update!(hide_hiatused_tags_owed: true)
            api_login_as(user)
            get :index, params: { owed: true }
            expect(result_ids).to eq([owed_post.id])
          end
        end

        it "combines with other filters" do
          api_login_as(user)
          board_post = create(:post, user: user, unjoined_authors: [other_user])
          create(:reply, post: board_post, user: other_user)
          get :index, params: { owed: true, board_id: board_post.board_id }
          expect(result_ids).to eq([board_post.id])
        end
      end
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

      it "keeps posts hidden from the editor anchored to their predecessor" do
        coauthor = create(:user)
        board = create(:board, writers: [coauthor])
        visible1 = create(:post, board: board, user: board.creator)
        hidden = create(:post, board: board, user: board.creator, privacy: :private)
        visible2 = create(:post, board: board, user: board.creator)

        expect(visible1.reload.section_order).to eq(0)
        expect(hidden.reload.section_order).to eq(1)
        expect(visible2.reload.section_order).to eq(2)

        api_login_as(coauthor)
        post :reorder, params: { ordered_post_ids: [visible2.id, visible1.id] }
        expect(response).to have_http_status(200)

        # hidden was after visible1 → stays after visible1 in the new order
        expect(visible2.reload.section_order).to eq(0)
        expect(visible1.reload.section_order).to eq(1)
        expect(hidden.reload.section_order).to eq(2)
      end

      it "keeps a leading hidden post at the start" do
        coauthor = create(:user)
        board = create(:board, writers: [coauthor])
        hidden = create(:post, board: board, user: board.creator, privacy: :private)
        visible1 = create(:post, board: board, user: board.creator)
        visible2 = create(:post, board: board, user: board.creator)

        expect(hidden.reload.section_order).to eq(0)
        expect(visible1.reload.section_order).to eq(1)
        expect(visible2.reload.section_order).to eq(2)

        api_login_as(coauthor)
        post :reorder, params: { ordered_post_ids: [visible2.id, visible1.id] }
        expect(response).to have_http_status(200)

        expect(hidden.reload.section_order).to eq(0)
        expect(visible2.reload.section_order).to eq(1)
        expect(visible1.reload.section_order).to eq(2)
      end

      it "omits posts not visible to the editor from the response" do
        coauthor = create(:user)
        board = create(:board, writers: [coauthor])
        visible1 = create(:post, board: board, user: board.creator)
        hidden = create(:post, board: board, user: board.creator, privacy: :private)
        visible2 = create(:post, board: board, user: board.creator)

        api_login_as(coauthor)
        post :reorder, params: { ordered_post_ids: [visible2.id, visible1.id] }
        expect(response).to have_http_status(200)
        expect(response.parsed_body['post_ids']).to eq([visible2.id, visible1.id])
        expect(response.parsed_body['post_ids']).not_to include(hidden.id)
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

      it "keeps posts hidden from the editor anchored to their predecessor in the section" do
        coauthor = create(:user)
        board = create(:board, writers: [coauthor])
        section = create(:board_section, board: board)
        visible1 = create(:post, board: board, section: section, user: board.creator)
        hidden = create(:post, board: board, section: section, user: board.creator, privacy: :private)
        visible2 = create(:post, board: board, section: section, user: board.creator)

        expect(visible1.reload.section_order).to eq(0)
        expect(hidden.reload.section_order).to eq(1)
        expect(visible2.reload.section_order).to eq(2)

        api_login_as(coauthor)
        post :reorder, params: { ordered_post_ids: [visible2.id, visible1.id], section_id: section.id }
        expect(response).to have_http_status(200)

        expect(visible2.reload.section_order).to eq(0)
        expect(visible1.reload.section_order).to eq(1)
        expect(hidden.reload.section_order).to eq(2)
      end
    end
  end
end
