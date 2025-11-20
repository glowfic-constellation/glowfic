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

    it "should affect nothing else when deleting an indexpost", :aggregate_failures do
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
end
