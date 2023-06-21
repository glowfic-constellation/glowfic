RSpec.describe BoardSection do
  include ActiveJob::TestHelper

  let(:continuity) { create(:continuity) }
  let(:section) { create(:board_section, board: continuity) }
  let(:section0) { create(:board_section, board: continuity) }
  let(:section1) { create(:board_section, board: continuity) }
  let(:section2) { create(:board_section, board: continuity) }
  let(:section3) { create(:board_section, board: continuity) }

  it "should reset section_* fields in posts after deletion" do
    create(:board_section, board: continuity)
    section
    section2 = create(:board_section, board: continuity)
    post = create(:post, board: continuity, section: section)
    expect(post.section_id).not_to be_nil
    expect(post.section_order).to eq(0)
    expect(section2.section_order).to eq(2)
    perform_enqueued_jobs(only: UpdateModelJob) do
      Audited.audit_class.as_user(continuity.creator) do
        section.destroy!
      end
    end
    post.reload
    expect(post.section_id).to be_nil
    expect(post.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
  end

  it "should autofill post section order when not specified" do
    post0 = create(:post, board: continuity, section: section)
    post1 = create(:post, board: continuity, section: section)
    post2 = create(:post, board: continuity, section: section)
    expect(post0.section_order).to eq(0)
    expect(post1.section_order).to eq(1)
    expect(post2.section_order).to eq(2)
  end

  it "should autofill continuity section order when not specified" do
    expect(section0.section_order).to eq(0)
    expect(section1.section_order).to eq(1)
    expect(section2.section_order).to eq(2)
  end

  it "should reorder upon deletion" do
    expect(section0.section_order).to eq(0)
    expect(section1.section_order).to eq(1)
    expect(section2.section_order).to eq(2)
    expect(section3.section_order).to eq(3)
    Audited.audit_class.as_user(continuity.creator) { section1.destroy! }
    expect(section0.reload.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
    expect(section3.reload.section_order).to eq(2)
  end

  it "should reorder upon continuity change" do
    expect(section0.section_order).to eq(0)
    expect(section1.section_order).to eq(1)
    expect(section2.section_order).to eq(2)
    expect(section3.section_order).to eq(3)
    section1.update!(board: create(:continuity))
    expect(section0.reload.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
    expect(section3.reload.section_order).to eq(2)
  end
end
