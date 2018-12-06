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
end
