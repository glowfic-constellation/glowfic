require "spec_helper"

RSpec.describe WritableHelper do
  describe "#shortened_desc" do
    it "uses full string if short enough" do
      text = 'a' * 100
      expect(helper.shortened_desc(text, 1)).to eq(text)
    end

    it "uses 255 chars if single long paragraph" do
      text = 'a' * 300
      more = '<a href="#" id="expanddesc-1" class="expanddesc">more &raquo;</a>'
      dots = '<span id="dots-1">... </span>'
      expand = '<span class="hidden" id="desc-1">' + ('a' * 45) + '</span>'
      expect(helper.shortened_desc(text, 1)).to eq('a' * 255 + dots + expand + more)
    end
  end

  describe "#anchored_board_path" do
    it "anchors for sectioned post" do
      section = create(:board_section)
      post = create(:post, board: section.board, section: section)
      expect(helper.anchored_board_path(post)).to eq(board_path(post.board_id) + "#section-" + section.id.to_s)
    end

    it "does not anchor for unsectioned post" do
      post = create(:post)
      expect(helper.anchored_board_path(post)).to eq(board_path(post.board_id))
    end
  end
end
