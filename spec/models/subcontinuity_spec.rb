require "spec_helper"

RSpec.describe Subcontinuity do
  it "should reset section_* fields in posts after deletion" do
    continuity = create(:continuity)
    Subcontinuity.create!(continuity: continuity, name: 'Test')
    section = Subcontinuity.create!(continuity: continuity, name: 'Test')
    section2 = Subcontinuity.create!(continuity: continuity, name: 'Test')
    post = create(:post, continuity: continuity, section_id: section.id)
    expect(post.section_id).not_to be_nil
    expect(post.section_order).to eq(0)
    expect(section2.section_order).to eq(2)
    section.destroy!
    post.reload
    expect(post.section_id).to be_nil
    expect(post.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
  end

  it "should autofill post section order when not specified" do
    continuity = create(:continuity)
    section = Subcontinuity.create!(continuity: continuity, name: 'Test')
    post0 = create(:post, continuity: continuity, section_id: section.id)
    post1 = create(:post, continuity: continuity, section_id: section.id)
    post2 = create(:post, continuity: continuity, section_id: section.id)
    expect(post0.section_order).to eq(0)
    expect(post1.section_order).to eq(1)
    expect(post2.section_order).to eq(2)
  end

  it "should autofill continuity section order when not specified" do
    continuity = create(:continuity)
    section0 = Subcontinuity.create!(continuity_id: continuity.id, name: 'Test')
    section1 = Subcontinuity.create!(continuity_id: continuity.id, name: 'Test')
    section2 = Subcontinuity.create!(continuity_id: continuity.id, name: 'Test')
    expect(section0.section_order).to eq(0)
    expect(section1.section_order).to eq(1)
    expect(section2.section_order).to eq(2)
  end

  it "should reorder upon deletion" do
    continuity = create(:continuity)
    section0 = create(:subcontinuity, continuity_id: continuity.id)
    expect(section0.section_order).to eq(0)
    section1 = create(:subcontinuity, continuity_id: continuity.id)
    expect(section1.section_order).to eq(1)
    section2 = create(:subcontinuity, continuity_id: continuity.id)
    expect(section2.section_order).to eq(2)
    section3 = create(:subcontinuity, continuity_id: continuity.id)
    expect(section3.section_order).to eq(3)
    section1.destroy!
    expect(section0.reload.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
    expect(section3.reload.section_order).to eq(2)
  end

  it "should reorder upon continuity change" do
    continuity = create(:continuity)
    section0 = create(:subcontinuity, continuity_id: continuity.id)
    expect(section0.section_order).to eq(0)
    section1 = create(:subcontinuity, continuity_id: continuity.id)
    expect(section1.section_order).to eq(1)
    section2 = create(:subcontinuity, continuity_id: continuity.id)
    expect(section2.section_order).to eq(2)
    section3 = create(:subcontinuity, continuity_id: continuity.id)
    expect(section3.section_order).to eq(3)
    section1.continuity = create(:continuity)
    section1.save!
    expect(section0.reload.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
    expect(section3.reload.section_order).to eq(2)
  end
end
