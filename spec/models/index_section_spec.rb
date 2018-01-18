require "spec_helper"

RSpec.describe IndexSection do
  it "should autofill post section order when not specified" do
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

  it "should autofill board section order on creation" do
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
    expect(section0.section_order).to eq(0)
    section1 = create(:index_section, index: index)
    expect(section1.section_order).to eq(1)
    section2 = create(:index_section, index: index)
    expect(section2.section_order).to eq(2)
    section3 = create(:index_section, index: index)
    expect(section3.section_order).to eq(3)
    section1.destroy
    expect(section0.reload.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
    expect(section3.reload.section_order).to eq(2)
  end

  it "should reorder upon index change" do
    index = create(:index)
    section0 = create(:index_section, index: index)
    expect(section0.section_order).to eq(0)
    section1 = create(:index_section, index: index)
    expect(section1.section_order).to eq(1)
    section2 = create(:index_section, index: index)
    expect(section2.section_order).to eq(2)
    section3 = create(:index_section, index: index)
    expect(section3.section_order).to eq(3)
    section1.index = create(:index)
    section1.save!
    expect(section0.reload.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
    expect(section3.reload.section_order).to eq(2)
  end
end
