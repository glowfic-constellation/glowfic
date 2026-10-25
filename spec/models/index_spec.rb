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

  describe ".visible_to" do
    let(:owner) { create(:user) }
    let!(:indexes) do
      Index.privacies.keys.map { |privacy| create(:index, user: owner, privacy: privacy) }
    end

    def expect_scope_to_match_instance_method(user)
      expected = indexes.select { |index| index.visible_to?(user) }
      expect(Index.visible_to(user)).to match_array(expected)
    end

    it "matches visible_to? when logged out" do
      expect_scope_to_match_instance_method(nil)
      expect(Index.visible_to(nil).map(&:privacy)).to eq(['public'])
    end

    it "matches visible_to? for the owner" do
      expect_scope_to_match_instance_method(owner)
      expect(Index.visible_to(owner).count).to eq(Index.privacies.size)
    end

    it "matches visible_to? for another full user" do
      expect_scope_to_match_instance_method(create(:user))
      expect(Index.visible_to(create(:user)).map(&:privacy)).to match_array(['public', 'registered', 'full_accounts'])
    end

    it "matches visible_to? for a reader account" do
      expect_scope_to_match_instance_method(create(:reader_user))
      expect(Index.visible_to(create(:reader_user)).map(&:privacy)).to match_array(['public', 'registered'])
    end

    it "matches visible_to? for a reader account owner" do
      reader = create(:reader_user)
      indexes << create(:index, user: reader, privacy: :private)
      expect_scope_to_match_instance_method(reader)
    end

    it "matches visible_to? for an admin" do
      expect_scope_to_match_instance_method(create(:admin_user))
      expect(Index.visible_to(create(:admin_user)).count).to eq(Index.privacies.size)
    end
  end
end
