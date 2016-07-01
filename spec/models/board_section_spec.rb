require "spec_helper"

RSpec.describe BoardSection do
  it "should reset section_* fields in posts after deletion" do
    board = create(:board)
    section = BoardSection.create(board: board, name: 'Test')
    post = create(:post, board: board, section_id: section.id)
    expect(post.section_id).not_to be_nil
    expect(post.section_order).not_to be_nil
    section.destroy
    post.reload
    expect(post.section_id).to be_nil
    expect(post.section_order).to be_nil
  end

  it "should autofill post section order when not specified" do
    board = create(:board)
    section = BoardSection.create(board: board, name: 'Test')
    post0 = create(:post, board: board, section_id: section.id)
    post1 = create(:post, board: board, section_id: section.id)
    post2 = create(:post, board: board, section_id: section.id)
    expect(post0.section_order).to eq(0)
    expect(post1.section_order).to eq(1)
    expect(post2.section_order).to eq(2)
  end

  it "should autofill board section order when not specified" do
    board = create(:board)
    section0 = BoardSection.create(board: board, name: 'Test')
    section1 = BoardSection.create(board: board, name: 'Test')
    section2 = BoardSection.create(board: board, name: 'Test')
    expect(section0.section_order).to eq(0)
    expect(section1.section_order).to eq(1)
    expect(section2.section_order).to eq(2)
  end
end
