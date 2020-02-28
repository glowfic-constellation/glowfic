require "spec_helper"

RSpec.describe Api::V1::PostsController do
  describe "GET index" do
    shared_examples_for "index.json" do |in_doc|
      let!(:post) { create(:post, subject: 'search') }

      it "should support no search", show_in_doc: in_doc do
        get :index
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(post.as_json(min: true).stringify_keys)
      end

      it "should support search", show_in_doc: in_doc do
        create(:post, subject: 'no')
        get :index, params: { q: 'se' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(post.as_json(min: true).stringify_keys)
      end

      it "hides private posts" do
        create(:post, privacy: Concealable::PRIVATE)
        get :index
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(post.as_json(min: true).stringify_keys)
      end
    end

    context "when logged in" do
      before(:each) { login }

      it_behaves_like "index.json", false
    end

    context "when logged out" do
      it_behaves_like "index.json", true
    end
  end

  describe "GET show" do
    it "requires valid post", :show_in_doc do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Post could not be found.")
    end

    it "requires access to post", :show_in_doc do
      post = create(:post, privacy: Concealable::PRIVATE)
      get :show, params: { id: post.id }
      expect(response).to have_http_status(403)
      expect(response.json['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "succeeds with valid post", :show_in_doc do
      post = create(:post, with_icon: true, with_character: true)
      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(post.id)
      expect(response.json['num_replies']).to eq(0)
      expect(response.json['authors'].size).to eq(1)
      expect(response.json['authors'][0]['id']).to eq(post.user_id)
      expect(response.json['content']).to eq(post.content)
      expect(response.json['icon']['id']).to eq(post.icon_id)
      expect(response.json['character']['id']).to eq(post.character_id)
    end
  end

  describe "POST reorder" do
    let(:user) { create(:user) }
    let(:board) { create(:board, creator: user) }
    let(:board2) { create(:board, creator: user) }

    it "requires login", :show_in_doc do
      post :reorder
      expect(response).to have_http_status(401)
      expect(response.json['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    context "without section_id" do
      let!(:post1) { create(:post, board: board) }
      let!(:post2) { create(:post, board: board) }
      let!(:post3) { create(:post, board: board) }
      let!(:post4) { create(:post, board: board) }
      let!(:post5) { create(:post, board: board2) }

      it "requires a board you have access to" do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [post2, post1].map(&:id)

        login
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(403)
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)
      end

      it "requires a single board without section_id" do
        post6 = create(:post, board: board2)

        expect(post1.reload.section_order).to eq(0)
        expect(post5.reload.section_order).to eq(0)
        expect(post6.reload.section_order).to eq(1)

        post_ids = [post6, post4, post1].map(&:id)
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one board')
        expect(post1.reload.section_order).to eq(0)
        expect(post5.reload.section_order).to eq(0)
        expect(post6.reload.section_order).to eq(1)
      end

      it "requires section_id if posts in section" do
        section = create(:board_section, board: board)
        post1 = create(:post, board: board, section: section)
        post2 = create(:post, board: board, section: section)

        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [post2, post1].map(&:id)
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one specified section in the board, or no section')
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)
      end

      it "requires valid post_ids" do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [-1]
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(404)
        expect(response.json['errors'][0]['message']).to eq('Some posts could not be found: -1')
      end

      it "works for valid changes", :show_in_doc do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)
        expect(post3.reload.section_order).to eq(2)
        expect(post4.reload.section_order).to eq(3)
        expect(post5.reload.section_order).to eq(0)

        post_ids = [post3, post1, post4, post2].map(&:id)

        login_as(board.creator)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(200)
        expect(response.json).to eq({'post_ids' => post_ids})
        expect(post1.reload.section_order).to eq(1)
        expect(post2.reload.section_order).to eq(3)
        expect(post3.reload.section_order).to eq(0)
        expect(post4.reload.section_order).to eq(2)
        expect(post5.reload.section_order).to eq(0)
      end

      it "works when specifying valid subset", :show_in_doc do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)
        expect(post3.reload.section_order).to eq(2)
        expect(post4.reload.section_order).to eq(3)
        expect(post5.reload.section_order).to eq(0)

        post_ids = [post3, post1].map(&:id)

        login_as(board.creator)
        post :reorder, params: { ordered_post_ids: post_ids }
        expect(response).to have_http_status(200)
        expect(response.json).to eq({'post_ids' => [post3, post1, post2, post4].map(&:id)})
        expect(post1.reload.section_order).to eq(1)
        expect(post2.reload.section_order).to eq(2)
        expect(post3.reload.section_order).to eq(0)
        expect(post4.reload.section_order).to eq(3)
        expect(post5.reload.section_order).to eq(0)
      end
    end

    context "with section_id" do
      let(:section) { create(:board_section, board: board) }
      let(:section2) { create(:board_section, board: board) }
      let!(:post1) { create(:post, board: board, section: section) }
      let!(:post2) { create(:post, board: board, section: section) }
      let!(:post3) { create(:post, board: board, section: section) }
      let!(:post4) { create(:post, board: board, section: section) }
      let!(:post5) { create(:post, board: board, section: section2) }

      it "requires a board you have access to" do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [post2, post1].map(&:id)

        login
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(403)
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)
      end

      it "requires a single section" do
        post6 = create(:post, board: board, section: section2)

        expect(post1.reload.section_order).to eq(0)
        expect(post5.reload.section_order).to eq(0)
        expect(post6.reload.section_order).to eq(1)

        post_ids = [post6, post5, post1].map(&:id)
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one specified section in the board, or no section')
        expect(post1.reload.section_order).to eq(0)
        expect(post5.reload.section_order).to eq(0)
        expect(post6.reload.section_order).to eq(1)
      end

      it "requires valid section id" do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [post2.id, post1.id]
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: 0 }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one specified section in the board, or no section')
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)
      end

      it "requires correct section id" do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [post2, post1].map(&:id)
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section2.id }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one specified section in the board, or no section')
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)
      end

      it "requires no section_id if posts not in section" do
        post1 = create(:post, board: board)
        post2 = create(:post, board: board)

        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [post2.id, post1.id]
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq('Posts must be from one specified section in the board, or no section')
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)
      end

      it "requires valid post_ids" do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)

        post_ids = [-1]
        login_as(user)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(404)
        expect(response.json['errors'][0]['message']).to eq('Some posts could not be found: -1')
      end

      it "works for valid changes", :show_in_doc do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)
        expect(post3.reload.section_order).to eq(2)
        expect(post4.reload.section_order).to eq(3)
        expect(post5.reload.section_order).to eq(0)

        post_ids = [post3, post1, post4, post2].map(&:id)

        login_as(board.creator)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(200)
        expect(response.json).to eq({'post_ids' => post_ids})
        expect(post1.reload.section_order).to eq(1)
        expect(post2.reload.section_order).to eq(3)
        expect(post3.reload.section_order).to eq(0)
        expect(post4.reload.section_order).to eq(2)
        expect(post5.reload.section_order).to eq(0)
      end

      it "works when specifying valid subset", :show_in_doc do
        expect(post1.reload.section_order).to eq(0)
        expect(post2.reload.section_order).to eq(1)
        expect(post3.reload.section_order).to eq(2)
        expect(post4.reload.section_order).to eq(3)
        expect(post5.reload.section_order).to eq(0)

        post_ids = [post3, post1].map(&:id)

        login_as(board.creator)
        post :reorder, params: { ordered_post_ids: post_ids, section_id: section.id }
        expect(response).to have_http_status(200)
        expect(response.json).to eq({'post_ids' => [post3, post1, post2, post4].map(&:id)})
        expect(post1.reload.section_order).to eq(1)
        expect(post2.reload.section_order).to eq(2)
        expect(post3.reload.section_order).to eq(0)
        expect(post4.reload.section_order).to eq(3)
        expect(post5.reload.section_order).to eq(0)
      end
    end
  end
end
