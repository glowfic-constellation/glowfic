require "spec_helper"

RSpec.describe Index do
  describe "destroy behavior" do
    let(:index) { create(:index) }
    let(:section) { create(:index_section, index: index) }
    let(:post) { create(:post) }
    let(:sectionpost) { create(:index_post, index_section: section, index: index, post: post) }

    before(:each) do
      post2 = create(:post)
      sectionlesspost = create(:index_post, index: index, post: post2)
      sectionpost # touch to create

      expect(Index.count).to eq(1)
      expect(IndexPost.count).to eq(2)
      expect(IndexSection.count).to eq(1)
      expect(Post.count).to eq(2)
    end

    it "should destroy indexposts and indexsections when deleting an index" do
      index.destroy

      expect(Index.count).to eq(0)
      expect(IndexPost.count).to eq(0)
      expect(IndexSection.count).to eq(0)
      expect(Post.count).to eq(2)
    end

    it "should relocate indexposts when deleting an indexsection" do
      section.destroy

      expect(Index.count).to eq(1)
      expect(IndexPost.count).to eq(2)
      expect(IndexSection.count).to eq(0)
      expect(Post.count).to eq(2)
    end

    it "should affect nothing else when deleting an indexpost" do
      other = create(:index_post, index_section: section, index: index)
      expect(sectionpost.section_order).to eq(0)
      expect(other.section_order).to eq(1)

      sectionpost.destroy

      expect(Index.count).to eq(1)
      expect(IndexPost.count).to eq(2)
      expect(other.reload.section_order).to eq(0)
      expect(IndexSection.count).to eq(1)
      expect(Post.count).to eq(3)
    end

    it "should delete indexposts when deleting a post" do
      post.destroy

      expect(Index.count).to eq(1)
      expect(IndexPost.count).to eq(1)
      expect(IndexSection.count).to eq(1)
      expect(Post.count).to eq(1)
    end
  end
end
