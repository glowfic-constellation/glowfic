RSpec.describe Tag::MetaTag do
  describe "validations" do
    it "rejects an edge between different tag types" do
      edge = Tag::MetaTag.new(parent_tag: create(:setting), child_tag: create(:label))
      expect(edge).not_to be_valid
      expect(edge.errors.full_messages.join).to include("same type")
    end

    it "rejects a self-implication" do
      setting = create(:setting)
      edge = Tag::MetaTag.new(parent_tag: setting, child_tag: setting)
      expect(edge).not_to be_valid
      expect(edge.errors.full_messages.join).to include("cannot imply itself")
    end

    it "rejects a direct cycle" do
      parent = create(:setting)
      child = create(:setting)
      Tag::MetaTag.create!(parent_tag: parent, child_tag: child)

      reverse = Tag::MetaTag.new(parent_tag: child, child_tag: parent)
      expect(reverse).not_to be_valid
      expect(reverse.errors.full_messages.join).to include("cycle")
    end

    it "rejects an indirect cycle" do
      a = create(:setting)
      b = create(:setting)
      c = create(:setting)
      Tag::MetaTag.create!(parent_tag: a, child_tag: b)
      Tag::MetaTag.create!(parent_tag: b, child_tag: c)

      closing = Tag::MetaTag.new(parent_tag: c, child_tag: a)
      expect(closing).not_to be_valid
    end

    it "rejects an edge that would close a cycle through a suggested edge" do
      a = create(:setting)
      b = create(:setting)
      Tag::MetaTag.create!(parent_tag: a, child_tag: b, suggested: true)

      expect(Tag::MetaTag.new(parent_tag: b, child_tag: a)).not_to be_valid
    end

    it "allows a diamond, which is not a cycle" do
      top = create(:setting)
      left = create(:setting)
      right = create(:setting)
      bottom = create(:setting)
      Tag::MetaTag.create!(parent_tag: top, child_tag: left)
      Tag::MetaTag.create!(parent_tag: top, child_tag: right)
      Tag::MetaTag.create!(parent_tag: left, child_tag: bottom)

      expect(Tag::MetaTag.new(parent_tag: right, child_tag: bottom)).to be_valid
    end
  end

  describe "traversal" do
    it "walks descendants transitively" do
      a = create(:setting)
      b = create(:setting)
      c = create(:setting)
      Tag::MetaTag.create!(parent_tag: a, child_tag: b)
      Tag::MetaTag.create!(parent_tag: b, child_tag: c)

      expect(a.descendant_ids).to match_array([b.id, c.id])
      expect(c.ancestor_ids).to match_array([a.id, b.id])
    end

    it "ignores suggested edges" do
      parent = create(:setting)
      child = create(:setting)
      Tag::MetaTag.create!(parent_tag: parent, child_tag: child, suggested: true)

      expect(parent.descendant_ids).to be_empty
    end

    it "terminates on a pre-existing cycle" do
      a = create(:setting)
      b = create(:setting)
      Tag::MetaTag.create!(parent_tag: a, child_tag: b)
      # Bypasses the validation the way an import or an older row would.
      Tag::MetaTag.new(parent_tag: b, child_tag: a).save!(validate: false)

      expect { Timeout.timeout(5) { a.descendant_ids } }.not_to raise_error
      expect(a.descendant_ids).to include(b.id)
    end
  end
end
