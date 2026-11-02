RSpec.describe Index do
  describe "destroy behavior" do
    let!(:index) { create(:index) }
    let!(:section) { create(:index_section, index: index) }
    let!(:post) { create(:post) }
    let!(:sectionpost) { create(:index_post, index_section: section, index: index, post: post) }

    before(:each) do
      create(:index_post, index: index)
    end

    it "should destroy indexposts and indexsections when deleting an index" do
      expect { index.destroy! }
        .to change { Index.count }.by(-1)
        .and change { IndexPost.count }.by(-2)
        .and change { IndexSection.count }.by(-1)
        .and not_change { Post.count }
    end

    it "should relocate indexposts when deleting an indexsection" do
      expect { section.destroy! }
        .to not_change { [Index.count, IndexPost.count, Post.count] }
        .and change { IndexSection.count }.by(-1)
    end

    it "should affect nothing else when deleting an indexpost" do
      other = create(:index_post, index_section: section, index: index)
      expect(sectionpost.section_order).to eq(0)
      expect(other.section_order).to eq(1)

      expect { sectionpost.destroy! }
        .to change { IndexPost.count }.by(-1)
        .and not_change { [Index.count, IndexSection.count, Post.count] }

      expect(other.reload.section_order).to eq(0)
    end

    it "should delete indexposts when deleting a post" do
      expect { post.destroy! }
        .to change { Post.count }.by(-1)
        .and change { IndexPost.count }.by(-1)
        .and not_change { [Index.count, IndexSection.count] }
    end
  end

  describe "#editable_by?" do
    it "requires the index to be visible to the user" do
      user = create(:user)
      index = create(:index, authors_locked: false)
      expect(index.editable_by?(user)).to eq(true)
      index.update!(privacy: :private)
      expect(index.editable_by?(user)).to eq(false)
      expect(index.editable_by?(index.user)).to eq(true)
    end
  end

  describe ".visible_to" do
    it "matches #visible_to? for every privacy and kind of user" do
      owner = create(:user)
      reader_owner = create(:reader_user)
      viewers = [nil, create(:user), create(:reader_user), create(:admin_user), owner, reader_owner]
      indexes = Index.privacies.keys.flat_map do |privacy|
        [create(:index, privacy: privacy, user: owner), create(:index, privacy: privacy, user: reader_owner)]
      end

      viewers.each do |viewer|
        expected = indexes.select { |index| index.visible_to?(viewer) }
        expect(Index.visible_to(viewer)).to match_array(expected)
      end
    end
  end
end
