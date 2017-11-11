require "spec_helper"
require "support/shared_examples_for_taggable"

RSpec.describe Setting do
  # from Taggable concern
  context "tags" do
    it_behaves_like 'taggable', 'parent_setting', :setting
  end

  context "#has_items?" do
    it "has items with a post" do
      harry_potter = create(:setting, name: 'Harry Potter')
      post = create(:post, subject: 'Harry Potter and the Goblet of Fire')
      harry_potter.posts << post
      expect(harry_potter).to have_items
    end

    it "has items with a character" do
      harry_potter = create(:setting, name: 'Harry Potter')
      hermione = create(:character, name: 'Hermione Granger')
      harry_potter.characters << hermione
      expect(harry_potter).to have_items
    end

    it "has items with a child setting" do
      harry_potter = create(:setting, name: 'Harry Potter')
      hazel = create(:setting, name: 'Hazel')
      harry_potter.child_settings << hazel
      expect(harry_potter.has_items?).to eq(true)
    end
  end
end
