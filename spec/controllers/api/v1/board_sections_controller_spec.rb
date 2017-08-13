require "spec_helper"

RSpec.describe Api::V1::BoardSectionsController do
  describe "POST reorder" do
    it "requires login", :show_in_doc do
      post :reorder
      expect(response).to have_http_status(401)
      expect(response.json['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires a board you have access to" do
      board = create(:board)
      board_post = create(:post, board_id: board.id)
      expect(board_post.reload.section_order).to eq(0)

      changes = {}
      changes[board_post.id] = {type: 'Post', order: 1}

      login
      post :reorder, changes: changes
      expect(response).to have_http_status(200)
      expect(board_post.reload.section_order).to eq(0)
    end

    it "requires valid section id" do
      board = create(:board)
      board_post = create(:post, board_id: board.id)
      expect(board_post.reload.section_order).to eq(0)

      changes = {}
      changes['not an id'] = {type: 'Post', order: 1}

      login_as(board.creator)
      post :reorder, changes: changes
      expect(response).to have_http_status(200)
      expect(board_post.reload.section_order).to eq(0)
    end

    it "requires valid type" do
      board = create(:board)
      board_post = create(:post, board_id: board.id)
      expect(board_post.reload.section_order).to eq(0)

      changes = {}
      changes[board_post.id] = {type: 'NotAType', order: 1}

      login_as(board.creator)
      post :reorder, changes: changes
      expect(response).to have_http_status(200)
      expect(board_post.reload.section_order).to eq(0)
    end

    it "works for valid changes", :show_in_doc do
      board = create(:board)
      board_post = create(:post, board_id: board.id)
      board_section = create(:board_section, board_id: board.id)
      board_post2 = create(:post, board_id: board.id)
      board_section2 = create(:board_section, board_id: board.id)

      expect(board_post.reload.section_order).to eq(0)
      expect(board_section.reload.section_order).to eq(0)
      expect(board_post2.reload.section_order).to eq(1)
      expect(board_section2.reload.section_order).to eq(1)

      changes = {}
      changes[board_post.id] = {type: 'Post', order: 1}
      changes[board_section.id] = {type: 'BoardSection', order: 1}
      changes[board_post2.id] = {type: 'Post', order: 0}
      changes[board_section2.id] = {type: 'BoardSection', order: 0}

      login_as(board.creator)
      post :reorder, changes: changes
      expect(response).to have_http_status(200)
      expect(response.json).to eq({})
      expect(board_post.reload.section_order).to eq(1)
      expect(board_section.reload.section_order).to eq(1)
      expect(board_post2.reload.section_order).to eq(0)
      expect(board_section2.reload.section_order).to eq(0)
    end
  end
end
