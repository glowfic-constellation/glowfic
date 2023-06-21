RSpec.describe BoardSection do
  include ActiveJob::TestHelper

  it "should reset section_* fields in posts after deletion" do
    board = create(:board)
    create(:board_section, board: board)
    section = create(:board_section, board: board)
    section2 = create(:board_section, board: board)
    post = create(:post, board: board, section: section)
    expect(post.section_id).not_to be_nil
    expect(post.section_order).to eq(0)
    expect(section2.section_order).to eq(2)
    perform_enqueued_jobs(only: UpdateModelJob) do
      Audited.audit_class.as_user(board.creator) do
        section.destroy!
      end
    end
    post.reload
    expect(post.section_id).to be_nil
    expect(post.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
  end

  it "should autofill post section order when not specified" do
    board = create(:board)
    section = create(:board_section, board: board)
    post0 = create(:post, board: board, section: section)
    post1 = create(:post, board: board, section: section)
    post2 = create(:post, board: board, section: section)
    expect(post0.section_order).to eq(0)
    expect(post1.section_order).to eq(1)
    expect(post2.section_order).to eq(2)
  end

  it "should autofill board section order when not specified" do
    board = create(:board)
    section0 = create(:board_section, board: board)
    section1 = create(:board_section, board: board)
    section2 = create(:board_section, board: board)
    expect(section0.section_order).to eq(0)
    expect(section1.section_order).to eq(1)
    expect(section2.section_order).to eq(2)
  end

  it "should reorder upon deletion" do
    board = create(:board)
    section0 = create(:board_section, board: board)
    expect(section0.section_order).to eq(0)
    section1 = create(:board_section, board: board)
    expect(section1.section_order).to eq(1)
    section2 = create(:board_section, board: board)
    expect(section2.section_order).to eq(2)
    section3 = create(:board_section, board: board)
    expect(section3.section_order).to eq(3)
    Audited.audit_class.as_user(board.creator) { section1.destroy! }
    expect(section0.reload.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
    expect(section3.reload.section_order).to eq(2)
  end

  it "should reorder upon board change" do
    board = create(:board)
    section0 = create(:board_section, board: board)
    expect(section0.section_order).to eq(0)
    section1 = create(:board_section, board: board)
    expect(section1.section_order).to eq(1)
    section2 = create(:board_section, board: board)
    expect(section2.section_order).to eq(2)
    section3 = create(:board_section, board: board)
    expect(section3.section_order).to eq(3)
    section1.board = create(:board)
    section1.save!
    expect(section0.reload.section_order).to eq(0)
    expect(section2.reload.section_order).to eq(1)
    expect(section3.reload.section_order).to eq(2)
  end
end
