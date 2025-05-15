RSpec.describe IndexSection do
  it "should autofill post section order when not specified", :aggregate_failures do
    index = create(:index)
    section = create(:index_section, index: index)
    post2 = create(:post, user: index.user)
    post0 = create(:post, user: index.user)
    post1 = create(:post, user: index.user)
    section.posts << post0
    section.posts << post1
    section.posts << post2
    expect(IndexPost.count).to eq(3)
    expect(section.reload.posts.count).to eq(3)
    expect(post0.index_posts.first.section_order).to eq(0)
    expect(post1.index_posts.first.section_order).to eq(1)
    expect(post2.index_posts.first.section_order).to eq(2)
  end

  it "should autofill board section order on creation", :aggregate_failures do
    index = create(:index)
    section0 = create(:index_section, index: index)
    section1 = create(:index_section, index: index)
    section2 = create(:index_section, index: index)
    expect(section0.section_order).to eq(0)
    expect(section1.section_order).to eq(1)
    expect(section2.section_order).to eq(2)
  end

  it "should reorder upon deletion" do
    index = create(:index)
    section0 = create(:index_section, index: index)
    section1 = create(:index_section, index: index)
    section2 = create(:index_section, index: index)
    section3 = create(:index_section, index: index)

    aggregate_failures do
      expect(section0.section_order).to eq(0)
      expect(section1.section_order).to eq(1)
      expect(section2.section_order).to eq(2)
      expect(section3.section_order).to eq(3)
    end

    section1.destroy!

    aggregate_failures do
      expect(section0.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
      expect(section3.reload.section_order).to eq(2)
    end
  end

  it "should reorder upon index change" do
    index = create(:index)
    section0 = create(:index_section, index: index)
    section1 = create(:index_section, index: index)
    section2 = create(:index_section, index: index)
    section3 = create(:index_section, index: index)

    aggregate_failures do
      expect(section0.section_order).to eq(0)
      expect(section1.section_order).to eq(1)
      expect(section2.section_order).to eq(2)
      expect(section3.section_order).to eq(3)
    end

    section1.index = create(:index)
    section1.save!

    aggregate_failures do
      expect(section0.reload.section_order).to eq(0)
      expect(section2.reload.section_order).to eq(1)
      expect(section3.reload.section_order).to eq(2)
    end
  end
end
