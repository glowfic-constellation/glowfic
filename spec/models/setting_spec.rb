require "spec_helper"

RSpec.describe Setting do
  describe "#has_items?" do
    it "has items with a post" do
      harry_potter = create(:setting, name: 'Harry Potter')
      create(:post, subject: 'Harry Potter and the Goblet of Fire', settings: [harry_potter])
      expect(harry_potter.taggings_count).to be > 0
    end

    it "has items with a character" do
      harry_potter = create(:setting, name: 'Harry Potter')
      create(:character, name: 'Hermione Granger', settings: [harry_potter])
      expect(harry_potter.taggings_count).to be > 0
    end

    it "has items with a child setting" do
      harry_potter = create(:setting, name: 'Harry Potter')
      create(:setting, name: 'Hazel', parents: [harry_potter])
      expect(harry_potter.taggings_count).to be > 0
    end
  end

  context "tags" do
    it "creates only in-memory tags on invalid create" do
      harry_potter = create(:setting, name: 'Harry Potter')
      setting = build(:setting, name: '', parents: [harry_potter])
      expect(setting.valid?).to eq(false)
      expect(setting.save).to eq(false)
      expect(setting.parents.count).to eq(0)
      expect(setting.parents.size).to eq(1)
      expect(ActsAsTaggableOn::Tagging.count).to eq(0)
    end

    it "creates tags on valid create" do
      harry_potter = create(:setting, name: 'Harry Potter')
      setting = build(:setting, parents: [harry_potter])
      expect(setting.valid?).to eq(true)
      expect(setting.save).to eq(true)
      expect(setting.parents.count).to eq(1)
      expect(setting.parents.size).to eq(1)
      expect(ActsAsTaggableOn::Tagging.count).to eq(1)
    end
  end

  context "associations" do
    it "tracks parents and children" do
      parent1 = create(:setting) # has child1, child2, and child3 as children
      parent2 = create(:setting) # has child2 as child
      child1 = create(:setting) # has parent1 as parent and child2 as child
      child2 = create(:setting) # has parent1, parent2, and child1 as parents
      child3 = create(:setting) # has parent1 as parent

      child1.setting_list = [parent1.name]
      child1.save!

      child2.update!(setting_list: [parent1, parent2, child1].map(&:name))
      child3.update!(setting_list: [parent1.name])

      expect(parent1.reload.children.ids).to match_array([child1, child2, child3].map(&:id))
      expect(parent2.children.ids).to eq([child2.id])
      expect(child1.children.ids).to eq([child2.id])

      expect(child1.parents.ids).to eq([parent1.id])
      expect(child2.parents.ids).to match_array([parent1, parent2, child1].map(&:id))
      expect(child3.parents.ids).to eq([parent1.id])
    end
  end
end
