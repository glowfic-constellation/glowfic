require "spec_helper"

RSpec.describe BoardSectionsController do
  let(:klass) { BoardSection }
  let(:parent_klass) { Board }
  let(:redirect_override) { boards_url }

  describe "GET new" do
    let(:klass) { Board }

    include_examples 'GET new with parent validations'

    it "works with board_id" do
      board = create(:board)
      login_as(board.creator)
      get :new, params: { board_id: board.id }
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("New Section")
    end

    it "works without board_id" do
      login
      get :new
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("New Section")
    end
  end

  describe "POST create" do
    include_examples 'POST create with parent validations'

    it "succeeds" do
      board = create(:board)
      login_as(board.creator)
      section_name = 'ValidSection'
      post :create, params: { board_section: {board_id: board.id, name: section_name} }
      expect(response).to redirect_to(edit_board_url(board))
      expect(flash[:success]).to eq("New section, #{section_name}, created for #{board.name}.")
      expect(assigns(:board_section).name).to eq(section_name)
    end
  end

  describe "GET show" do
    include_examples 'GET show validations'

    it "orders posts correctly" do
      board = create(:board)
      section = create(:board_section, board: board)
      post5 = create(:post, board: board, section: section)
      post1 = create(:post, board: board, section: section)
      post4 = create(:post, board: board, section: section)
      post3 = create(:post, board: board, section: section)
      post2 = create(:post, board: board, section: section)
      post1.update!(section_order: 1)
      post2.update!(section_order: 2)
      post3.update!(section_order: 3)
      post4.update!(section_order: 4)
      post5.update!(section_order: 5)
      get :show, params: { id: section.id }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq(section.name)
      expect(assigns(:posts)).to eq([post1, post2, post3, post4, post5])
    end

    it "calculates OpenGraph data" do
      user = create(:user, username: 'John Doe')
      board = create(:board, name: 'board', creator: user, writers: [create(:user, username: 'Jane Doe')])
      section = create(:board_section, name: 'section', board: board, description: "test description")
      create(:post, subject: 'title', user: user, board: board, section: section)
      get :show, params: { id: section.id }

      meta_og = assigns(:meta_og)
      expect(meta_og.keys).to match_array([:url, :title, :description])
      expect(meta_og[:url]).to eq(board_section_url(section))
      expect(meta_og[:title]).to eq('board » section')
      expect(meta_og[:description]).to eq("Jane Doe, John Doe – 1 post\ntest description")
    end
  end

  describe "GET edit" do
    include_examples 'GET edit with parent validations'
  end

  describe "PUT update" do
    include_examples 'PUT update with parent validations'

    it "succeeds" do
      board_section = create('board_section', name: 'TestSection1')
      login_as(board_section.board.creator)
      section_name = 'TestSection2'
      put :update, params: { id: board_section.id, board_section: {name: section_name} }
      expect(response).to redirect_to(board_section_path(board_section))
      expect(board_section.reload.name).to eq(section_name)
      expect(flash[:success]).to eq("Section updated.")
    end
  end

  describe "DELETE destroy" do
    include_examples 'DELETE destroy with parent validations'

    it "handles destroy failure" do
      section = create('board_section')
      post = create(:post, user: section.board.creator, board: section.board, section: section)
      login_as(section.board.creator)
      expect_any_instance_of(BoardSection).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      delete :destroy, params: { id: section.id }
      expect(response).to redirect_to(board_section_url(section))
      expect(flash[:error]).to eq("Section could not be deleted.")
      expect(post.reload.section).to eq(section)
    end
  end
end
