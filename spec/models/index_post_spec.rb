RSpec.describe IndexPost do
  it "should autofill post section order on creation", :aggregate_failures do
    index = create(:index)
    post2 = create(:post, user: index.user)
    post0 = create(:post, user: index.user)
    post1 = create(:post, user: index.user)
    index.posts << post0
    index.posts << post1
    index.posts << post2
    expect(IndexPost.count).to eq(3)
    expect(index.reload.posts.count).to eq(3)
    expect(post0.index_posts.first.section_order).to eq(0)
    expect(post1.index_posts.first.section_order).to eq(1)
    expect(post2.index_posts.first.section_order).to eq(2)
  end

  it "should reorder upon deletion" do
    index = create(:index)
    post2 = create(:post, user: index.user)
    post0 = create(:post, user: index.user)
    post1 = create(:post, user: index.user)
    index.posts << post0
    index.posts << post1
    index.posts << post2

    aggregate_failures do
      expect(post0.index_posts.first.section_order).to eq(0)
      expect(post1.index_posts.first.section_order).to eq(1)
      expect(post2.index_posts.first.section_order).to eq(2)
    end

    index.posts.destroy(post1)

    aggregate_failures do
      expect(post0.index_posts.first.section_order).to eq(0)
      expect(post2.index_posts.first.section_order).to eq(1)
    end
  end
end
