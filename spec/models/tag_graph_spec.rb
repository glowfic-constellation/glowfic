RSpec.describe Tag do
  describe "synonyms" do
    it "rejects a merger of a different type" do
      label = create(:label)
      setting = create(:setting, canonical: true)
      label.merger = setting
      expect(label).not_to be_valid
      expect(label.errors.full_messages.join).to include("same type")
    end

    it "rejects a merger that is not itself canonical" do
      target = create(:label)
      tag = create(:label)
      tag.merger = target
      expect(tag).not_to be_valid
      expect(tag.errors.full_messages.join).to include("canonical")
    end

    it "rejects a tag that is both canonical and a synonym" do
      target = create(:label, canonical: true)
      tag = create(:label, canonical: true)
      tag.merger = target
      expect(tag).not_to be_valid
    end

    it "reports whether a tag is a synonym" do
      target = create(:label, canonical: true)
      tag = create(:label)
      expect(tag).not_to be_synonym
      tag.update!(merger: target)
      expect(tag.reload).to be_synonym
    end

    it "resolves canonical_tag through the merger" do
      target = create(:label, canonical: true)
      tag = create(:label)
      tag.update!(merger: target)
      expect(tag.canonical_tag).to eq(target)
      expect(target.canonical_tag).to eq(target)
    end
  end

  describe "#merge_as_synonym" do
    let(:target) { create(:label, name: 'Bar Fight') }
    let(:loser) { create(:label, name: 'Barfight') }

    it "re-points taggings and keeps the loser as a synonym" do
      post = create(:post, labels: [loser])
      target.merge_as_synonym(loser)

      expect(post.reload.labels).to eq([target])
      expect(loser.reload.merger).to eq(target)
      expect(loser).not_to be_canonical
      expect(target.reload).to be_canonical
      expect(Tag.find_by(id: loser.id)).to be_present
    end

    it "drops taggings that would collide" do
      post = create(:post, labels: [target, loser])
      expect { target.merge_as_synonym(loser) }.to change { PostTag.count }.by(-1)
      expect(post.reload.labels).to eq([target])
    end

    it "keeps synonym chains one level deep" do
      grand_loser = create(:label)
      loser.update!(canonical: true)
      grand_loser.update!(merger: loser)

      target.merge_as_synonym(loser)

      expect(grand_loser.reload.merger).to eq(target)
      expect(loser.reload.merger).to eq(target)
    end

    it "refuses to merge across types" do
      setting = create(:setting)
      expect { setting.merge_as_synonym(target) }.to raise_error(ArgumentError)
    end

    it "refuses to merge a tag into itself" do
      expect { target.merge_as_synonym(target) }.to raise_error(ArgumentError)
    end
  end

  describe "#merge_with" do
    it "destroys the loser" do
      target = create(:label)
      loser = create(:label)
      post = create(:post, labels: [loser])

      target.merge_with(loser)

      expect(Tag.find_by(id: loser.id)).to be_nil
      expect(post.reload.labels).to eq([target])
    end
  end

  describe "scopes" do
    it "awaiting_wrangling excludes synonyms, unwrangleable and canonical tags" do
      plain = create(:label)
      create(:label, canonical: true)
      create(:label, unwrangleable: true)
      canonical = create(:label, canonical: true)
      create(:label).update!(merger: canonical)

      expect(Label.awaiting_wrangling).to eq([plain])
    end
  end
end
