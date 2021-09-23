RSpec.describe Board do
  include ActiveJob::TestHelper

  describe "validations" do
    it "succeeds" do
      expect(create(:continuity)).to be_valid
    end

    it "succeeds with multiple continuities with a single creator" do
      user = create(:user)
      create(:continuity, creator: user)
      second = build(:continuity, creator: user)
      expect(second).to be_valid
    end

    it "should require a name" do
      continuity = build(:continuity, name: '')
      expect(continuity).not_to be_valid
    end

    it "should require a unique name" do
      create(:continuity, name: 'Test Continuity')
      continuity = build(:continuity, name: 'Test Continuity')
      expect(continuity).not_to be_valid
    end
  end

  it "should allow everyone to post if open to anyone" do
    continuity = create(:continuity)
    user = create(:user)
    expect(continuity.authors_locked?).to be(false)
    expect(user.writes_in?(continuity)).to be(true)
  end

  describe "coauthors" do
    let(:coauthor) { create(:user) }
    let(:cameo) { create(:user) }
    let(:continuity) { create(:continuity, writers: [coauthor], cameos: [cameo], authors_locked: true) }

    it "should list the correct writers" do
      create(:user)
      continuity.reload
      expect(continuity.writer_ids).to match_array([continuity.creator_id, coauthor.id])
    end

    it "should allow coauthors and cameos to post" do
      expect(continuity.authors_locked?).to be(true)
      expect(coauthor.writes_in?(continuity)).to be(true)
      expect(cameo.writes_in?(continuity)).to be(true)
    end

    it "should allow coauthors but not cameos to edit" do
      expect(continuity.editable_by?(coauthor)).to be(true)
      expect(continuity.editable_by?(cameo)).to be(false)
    end

    it "should allow coauthors only once per continuity" do
      create(:user)
      expect { continuity.board_authors.create!(user: coauthor) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "should allow a user to be an author of multiple continuities" do
      continuity
      continuity2 = create(:continuity)
      author = continuity2.board_authors.build(user: coauthor)
      expect(author).to be_valid
    end
  end

  it "should be fixable via admin method" do
    continuity = create(:continuity)
    post = create(:post, board: continuity)
    create_list(:post, 3, board: continuity)
    post.update_columns(section_order: 2) # rubocop:disable Rails/SkipsModelValidations
    section = create(:board_section, board: continuity)
    create_list(:board_section, 2, board: continuity)
    section.update_columns(section_order: 6) # rubocop:disable Rails/SkipsModelValidations
    expect(continuity.posts.ordered_in_section.pluck(:section_order)).to eq([1, 2, 2, 3])
    expect(continuity.board_sections.ordered.pluck(:section_order)).to eq([1, 2, 6])
    continuity.send(:fix_ordering)
    expect(continuity.posts.ordered_in_section.pluck(:section_order)).to eq([0, 1, 2, 3])
    expect(continuity.board_sections.ordered.pluck(:section_order)).to eq([0, 1, 2])
  end

  describe "#ordered?" do
    it "should be unordered for default continuity" do
      expect(create(:continuity).ordered?).to eq(false)
    end

    it "should be ordered if continuity is not open to anyone" do
      continuity = create(:continuity, authors_locked: true)
      expect(continuity.ordered?).to eq(true)
      continuity.update!(authors_locked: false)
      expect(continuity.ordered?).to eq(false)
    end

    it "should be ordered if continuity has sections" do
      continuity = create(:continuity)
      create(:board_section, board: continuity)
      expect(continuity.ordered?).to eq(true)
    end
  end

  it "deletes sections but moves posts to sandboxes" do
    continuity = create(:continuity)
    create(:continuity, id: Board::ID_SANDBOX)
    section = create(:board_section, board: continuity)
    post = create(:post, board: continuity, section: section)
    perform_enqueued_jobs(only: UpdateModelJob) do
      Audited.audit_class.as_user(continuity.creator) { continuity.destroy! }
    end
    post.reload
    expect(post.board_id).to eq(3)
    expect(post.section).to be_nil
    expect(BoardSection.find_by_id(section.id)).to be_nil
  end
end
