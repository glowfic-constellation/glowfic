require "spec_helper"

RSpec.describe BoardsController do
  include ActiveJob::TestHelper

  describe "GET index" do
    context "without a user_id" do
      it "succeeds when logged out" do
        get :index
        expect(response.status).to eq(200)
      end

      it "succeeds when logged in" do
        login
        get :index
        expect(response.status).to eq(200)
      end

      it "sets correct variables" do
        user = create(:user)
        board1 = create(:board, creator_id: user.id)
        board2 = create(:board, creator_id: user.id)

        get :index
        expect(assigns(:boards)).to match_array([board1, board2])
        expect(assigns(:page_title)).to eq('Continuities')
      end
    end

    context "with a user_id" do
      it "does not require login" do
        user = create(:user)
        get :index, params: { user_id: user.id }
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:page_title)).to eq("#{user.username}'s Continuities")
      end

      it "defaults to current user if user id invalid" do
        user = create(:user)
        login_as(user)
        get :index, params: { user_id: -1 }
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:page_title)).to eq('Your Continuities')
      end

      it "displays error if user id invalid and logged out" do
        get :index, params: { user_id: -1 }
        expect(flash[:error]).to eq('User could not be found.')
        expect(response).to redirect_to(root_url)
      end

      it "sets correct variables" do
        user = create(:user)
        owned_board = create(:board, creator_id: user.id)

        get :index, params: { user_id: user.id }
        expect(assigns(:boards)).to match_array([owned_board])

        coauthor = create(:user)
        owned_board2 = create(:board, creator_id: user.id)
        owned_board2.coauthors << coauthor
        owned_board3 = create(:board, creator_id: user.id)
        owned_board3.cameos << coauthor

        get :index, params: { user_id: coauthor.id }
        expect(assigns(:boards)).to match_array([owned_board2])
        expect(assigns(:cameo_boards)).to match_array([owned_board3])
      end

      it "orders boards correctly" do
        user = create(:user)
        owned_board1 = create(:board, creator_id: user.id, name: 'd')
        owned_board2 = create(:board, creator_id: user.id, name: 'b')
        author_board1 = create(:board, coauthors: [user], name: 'a')
        author_board2 = create(:board, coauthors: [user], name: 'c')
        cameo_board1 = create(:board, cameos: [user], name: 'b')
        cameo_board2 = create(:board, cameos: [user], name: 'a')
        cameo_board3 = create(:board, cameos: [user], name: 'c')

        get :index, params: { user_id: user.id }
        expect(assigns(:boards)).to eq([author_board1, owned_board2, author_board2, owned_board1])
        expect(assigns(:cameo_boards)).to eq([cameo_board2, cameo_board1, cameo_board3])
      end
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :new
      expect(response.status).to eq(200)
    end

    it "sets correct variables" do
      user_id = login
      current_user = User.find(user_id)
      other_users = Array.new(3) { create(:user) }

      get :new

      expect(assigns(:board)).to be_an_instance_of(Board)
      expect(assigns(:board)).to be_a_new_record
      expect(assigns(:board).creator_id).to eq(user_id)
      expect(assigns(:page_title)).to eq("New Continuity")

      expect(assigns(:authors).size).to eq(3)
      expect(assigns(:authors)).to match_array(other_users)
      expect(assigns(:authors)).not_to include(current_user)
      expect(assigns(:authors).sort_by(&:username)).to eq(assigns(:authors))

      expect(assigns(:cameos).size).to eq(3)
      expect(assigns(:cameos)).to match_array(other_users)
      expect(assigns(:cameos)).not_to include(current_user)
      expect(assigns(:cameos).sort_by(&:username)).to eq(assigns(:cameos))
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Continuity could not be created.")
      expect(flash[:error][:array]).to be_present
      expect(response).to render_template('new')
    end

    it "sets correct variables on failure" do
      login
      other_users = Array.new(3) { create(:user) }

      post :create

      expect(assigns(:board)).to be_an_instance_of(Board)
      expect(assigns(:board)).to be_a_new_record
      expect(assigns(:board)).not_to be_valid
      expect(assigns(:board).creator).to eq(assigns(:current_user))
      expect(assigns(:page_title)).to eq("New Continuity")

      expect(assigns(:authors).size).to eq(3)
      expect(assigns(:authors)).to match_array(other_users)
      expect(assigns(:authors)).not_to include(assigns(:current_user))
      expect(assigns(:authors).sort_by(&:username)).to eq(assigns(:authors))

      expect(assigns(:cameos).size).to eq(3)
      expect(assigns(:cameos)).to match_array(other_users)
      expect(assigns(:cameos)).not_to include(assigns(:current_user))
      expect(assigns(:cameos).sort_by(&:username)).to eq(assigns(:cameos))
    end

    it "successfully makes a board" do
      expect(Board.count).to eq(0)
      creator = create(:user)
      login_as(creator)
      user2 = create(:user)
      user3 = create(:user)

      post :create, params: { board: {name: 'TestCreateBoard', description: 'Test description', coauthor_ids: [user2.id], cameo_ids: [user3.id]} }
      expect(response).to redirect_to(boards_url)
      expect(flash[:success]).to eq("Continuity created!")
      expect(Board.count).to eq(1)

      board = Board.first
      expect(board.name).to eq('TestCreateBoard')
      expect(board.creator).to eq(creator)
      expect(board.description).to eq('Test description')
      expect(board.coauthors).to match_array([user2])
      expect(board.cameos).to match_array([user3])
    end
  end

  describe "GET show" do
    it "requires valid board" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "succeeds with valid board" do
      board = create(:board)
      get :show, params: { id: board.id }
      expect(response.status).to eq(200)
    end

    it "succeeds for logged in users with valid board" do
      login
      board = create(:board)
      get :show, params: { id: board.id }
      expect(response.status).to eq(200)
    end

    it "only fetches the board's first 25 posts" do
      board = create(:board)
      26.times do create(:post, board: board) end
      get :show, params: { id: board.id }
      expect(assigns(:posts).size).to eq(25)
    end

    it "orders the posts by tagged_at in unordered boards" do
      board = create(:board)
      3.times do create(:post, board: board, tagged_at: Time.now + rand(5..30).hours) end
      get :show, params: { id: board.id }
      expect(assigns(:posts)).to eq(assigns(:posts).sort_by(&:tagged_at).reverse)
    end

    it "orders the posts correctly in ordered boards" do
      board = create(:board)
      section2 = create(:board_section, board: board)
      section1 = create(:board_section, board: board)
      section1.update_attributes!(section_order: 0)
      section2.update_attributes!(section_order: 1)
      post1 = create(:post, board: board, section: section1, tagged_at: Time.now + rand(5..30).hours)
      post2 = create(:post, board: board, section: section1, tagged_at: Time.now + rand(5..30).hours)
      post3 = create(:post, board: board, section: section1, tagged_at: Time.now + rand(5..30).hours)
      post4 = create(:post, board: board, section: section2, tagged_at: Time.now + rand(5..30).hours)
      post5 = create(:post, board: board, section: section2, tagged_at: Time.now + rand(5..30).hours)
      post6 = create(:post, board: board, section: section2, tagged_at: Time.now + rand(5..30).hours)
      post7 = create(:post, board: board, tagged_at: Time.now + rand(5..30).hours)
      post8 = create(:post, board: board, tagged_at: Time.now + rand(5..30).hours)
      post9 = create(:post, board: board, tagged_at: Time.now + rand(5..30).hours)
      post1.update_attributes!(section_order: 0)
      post2.update_attributes!(section_order: 1)
      post3.update_attributes!(section_order: 2)
      post4.update_attributes!(section_order: 0)
      post5.update_attributes!(section_order: 1)
      post6.update_attributes!(section_order: 2)
      post7.update_attributes!(section_order: 0)
      post8.update_attributes!(section_order: 1)
      post9.update_attributes!(section_order: 2)
      get :show, params: { id: board.id }
      expect(assigns(:board_sections).map(&:posts)).to eq([[post1, post2, post3], [post4, post5, post6]])
      expect(assigns(:posts)).to eq([post7, post8, post9])
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid board" do
      login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires board permission" do
      user = create(:user)
      login_as(user)
      board = create(:board)
      expect(board).not_to be_editable_by(user)
      get :edit, params: { id: board.id }
      expect(response).to redirect_to(board_url(board))
      expect(flash[:error]).to eq("You do not have permission to edit that continuity.")
    end

    it "succeeds with valid board" do
      board = create(:board)
      login_as(board.creator)
      get :edit, params: { id: board.id }
      expect(response.status).to eq(200)
    end

    it "sets expected variables" do
      board = create(:board)
      sections = [create(:board_section, board: board), create(:board_section, board: board)]
      posts = [create(:post, board: board, tagged_at: Time.now + 5.minutes), create(:post, board: board)]
      sections[0].update_attributes!(section_order: 1)
      sections[1].update_attributes!(section_order: 0)
      board.coauthors << create(:user)
      login_as(board.creator)
      get :edit, params: { id: board.id }
      expect(assigns(:board_sections)).to eq(sections.reverse)
      expect(assigns(:unsectioned_posts)).to eq(posts)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid board" do
      login
      put :update, params: { id: -1 }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires board permission" do
      user = create(:user)
      login_as(user)
      board = create(:board)
      expect(board).not_to be_editable_by(user)
      put :update, params: { id: board.id }
      expect(response).to redirect_to(board_url(board))
      expect(flash[:error]).to eq("You do not have permission to edit that continuity.")
    end

    it "requires valid params" do
      user = create(:user)
      board = create(:board, creator: user)
      login_as(user)
      put :update, params: { id: board.id, board: {name: ''} }
      expect(response).to render_template('edit')
      expect(flash[:error][:message]).to eq("Continuity could not be created.")
      expect(flash[:error][:array]).to be_present
    end

    it "succeeds" do
      user = create(:user)
      board = create(:board, creator: user)
      name = board.name
      login_as(user)
      user2 = create(:user)
      user3 = create(:user)
      put :update, params: { id: board.id, board: {name: name + 'edit', description: 'New description', coauthor_ids: [user2.id], cameo_ids: [user3.id]} }
      expect(response).to redirect_to(board_url(board))
      expect(flash[:success]).to eq("Continuity saved!")
      board.reload
      expect(board.name).to eq(name + 'edit')
      expect(board.description).to eq('New description')
      expect(board.coauthors).to match_array([user2])
      expect(board.cameos).to match_array([user3])
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid board" do
      login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires board permission" do
      user = create(:user)
      login_as(user)
      board = create(:board)
      expect(board).not_to be_editable_by(user)
      delete :destroy, params: { id: board.id }
      expect(response).to redirect_to(board_url(board))
      expect(flash[:error]).to eq("You do not have permission to edit that continuity.")
    end

    it "succeeds" do
      board = create(:board)
      login_as(board.creator)
      delete :destroy, params: { id: board.id }
      expect(response).to redirect_to(boards_url)
      expect(flash[:success]).to eq("Continuity deleted.")
    end

    it "moves posts to sandboxes" do
      board = create(:board)
      create(:board, id: 3) # sandbox
      section = create(:board_section, board: board)
      post = create(:post, board: board, section: section)
      login_as(board.creator)
      perform_enqueued_jobs(only: UpdateModelJob) do
        delete :destroy, params: { id: board.id }
      end
      expect(response).to redirect_to(boards_url)
      expect(flash[:success]).to eq('Continuity deleted.')
      post.reload
      expect(post.board_id).to eq(3)
      expect(post.section).to be_nil
      expect(BoardSection.find_by_id(section.id)).to be_nil
    end

    it "handles destroy failure" do
      board = create(:board)
      post = create(:post, user: board.creator, board: board)
      login_as(board.creator)
      expect_any_instance_of(Board).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      delete :destroy, params: { id: board.id }
      expect(response).to redirect_to(board_url(board))
      expect(flash[:error]).to eq({message: "Continuity could not be deleted.", array: []})
      expect(post.reload.board).to eq(board)
    end
  end

  describe "POST mark" do
    it "requires login" do
      post :mark
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires board id" do
      login
      post :mark
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires valid board id" do
      login
      post :mark, params: { board_id: -1 }
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires valid action" do
      login
      post :mark, params: { board_id: create(:board).id }
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Please choose a valid action.")
    end

    it "successfully marks board read" do
      board = create(:board)
      user = create(:user)
      login_as(user)
      now = Time.now
      expect(board.last_read(user)).to be_nil
      post :mark, params: { board_id: board.id, commit: "Mark Read" }
      expect(Board.find(board.id).last_read(user)).to be >= now # reload to reset cached @view
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("#{board.name} marked as read.")
    end

    it "successfully ignores board" do
      board = create(:board)
      user = create(:user)
      login_as(user)
      expect(board).not_to be_ignored_by(user)
      post :mark, params: { board_id: board.id, commit: "Hide from Unread" }
      expect(Board.find(board.id)).to be_ignored_by(user) # reload to reset cached @view
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("#{board.name} hidden from this page.")
    end
  end

  describe "#set_available_cowriters" do
    it "gets the correct set of available cowriters" do
      login
      users = Array.new(3) { create(:user) }
      controller.send(:set_available_cowriters)
      expect(assigns(:cameos)).to match_array(users)
      expect(assigns(:authors)).to match_array(users)
    end

    it "gets the correct set of available cowriters on an existing board" do
      users = Array.new(3) { create(:user) }
      coauthors = [create(:user)]
      cameos = [create(:user), create(:user)]
      board = create(:board, coauthors: coauthors, cameos: cameos)
      login_as(board.creator)
      controller.instance_variable_set(:@board, board)
      controller.send(:set_available_cowriters)
      expect(assigns(:cameos)).to match_array(users + cameos)
      expect(assigns(:authors)).to match_array(users + coauthors)
    end

    it "orders them correctly" do
      login
      user2 = create(:user, username: 'user2')
      user1 = create(:user, username: 'user1')
      user3 = create(:user, username: 'user3')
      controller.send(:set_available_cowriters)
      expect(assigns(:cameos)).to eq([user1, user2, user3])
      expect(assigns(:authors)).to eq([user1, user2, user3])
    end
  end
end
