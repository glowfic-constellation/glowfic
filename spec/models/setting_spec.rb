require "spec_helper"

RSpec.describe Setting do
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

  context "tags" do
    it "creates only in-memory tags on invalid create" do
      harry_potter = create(:setting, name: 'Harry Potter')
      setting = build(:setting, name: '', parent_settings: [harry_potter])
      expect(setting.valid?).to eq(false)
      expect(setting.save).to eq(false)
      expect(setting.parent_settings.count).to eq(0)
      expect(setting.parent_settings.size).to eq(1)
      expect(TagTag.count).to eq(0)
    end

    it "creates tags on valid create" do
      harry_potter = create(:setting, name: 'Harry Potter')
      setting = build(:setting, parent_settings: [harry_potter])
      expect(setting.valid?).to eq(true)
      expect(setting.save).to eq(true)
      expect(setting.parent_settings.count).to eq(1)
      expect(setting.parent_settings.size).to eq(1)
      expect(TagTag.count).to eq(1)
    end
  end
end
