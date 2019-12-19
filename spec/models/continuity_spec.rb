require "spec_helper"

RSpec.describe Continuity do
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
      expect { second.save! }.not_to raise_error
    end

    it "should require a name" do
      continuity = build(:continuity, name: '')
      expect(continuity).not_to be_valid
      continuity.name = 'Name'
      expect(continuity).to be_valid
    end

    it "should require a unique name" do
      create(:continuity, name: 'Test Continuity')
      continuity = build(:continuity, name: 'Test Continuity')
      expect(continuity).not_to be_valid
      continuity.name = 'Name'
      expect(continuity).to be_valid
    end
  end

  it "should allow everyone to post if open to anyone" do
    continuity = create(:continuity)
    user = create(:user)
    expect(continuity.authors_locked?).to be false
    expect(user.writes_in?(continuity)).to be true
  end

  describe "coauthors" do
    it "should list the correct writers" do
      continuity = create(:continuity)
      coauthor = create(:user)
      cameo = create(:user)
      create(:user) # not_continuity
      continuity.continuity_authors.create!(user: coauthor)
      continuity.continuity_authors.create!(user: cameo, cameo: true)
      continuity.reload
      expect(continuity.writer_ids).to match_array([continuity.creator_id, coauthor.id])
    end

    it "should allow coauthors and cameos to post" do
      coauthor = create(:user)
      cameo = create(:user)
      continuity = create(:continuity, writers: [coauthor], cameos: [cameo], authors_locked: true)
      expect(continuity.authors_locked?).to be true
      expect(coauthor.writes_in?(continuity)).to be true
      expect(cameo.writes_in?(continuity)).to be true
    end

    it "should allow coauthors but not cameos to edit" do
      continuity = create(:continuity)
      coauthor = create(:user)
      cameo = create(:user)
      continuity.continuity_authors.create!(user: coauthor)
      continuity.continuity_authors.create!(user: cameo, cameo: true)
      continuity.reload
      expect(continuity.editable_by?(coauthor)).to be true
      expect(continuity.editable_by?(cameo)).to be false
    end

    it "should allow coauthors only once per continuity" do
      continuity = create(:continuity)
      continuity2 = create(:continuity)
      coauthor = create(:user)
      cameo = create(:user) # FIXME: unused
      continuity.continuity_authors.create!(user: coauthor)
      expect { continuity.continuity_authors.create!(user: coauthor) }.to raise_error(ActiveRecord::RecordInvalid)
      continuity2.continuity_authors.create!(user: coauthor)
      continuity.reload
      continuity2.reload
      expect(continuity.continuity_authors.count).to eq(2)
      expect(continuity2.continuity_authors.count).to eq(2)
    end
  end

  it "should be fixable via admin method" do
    continuity = create(:continuity)
    post = create(:post, continuity: continuity)
    create(:post, continuity: continuity) # post2
    create(:post, continuity: continuity) # post3
    create(:post, continuity: continuity) # post4
    post.update_columns(section_order: 2)
    section = create(:subcontinuity, continuity: continuity)
    create(:subcontinuity, continuity: continuity) # section2
    create(:subcontinuity, continuity: continuity) # section3
    section.update_columns(section_order: 6)
    expect(continuity.posts.ordered_in_section.pluck(:section_order)).to eq([1, 2, 2, 3])
    expect(continuity.subcontinuities.ordered.pluck(:section_order)).to eq([1, 2, 6])
    continuity.send(:fix_ordering)
    expect(continuity.posts.ordered_in_section.pluck(:section_order)).to eq([0, 1, 2, 3])
    expect(continuity.subcontinuities.ordered.pluck(:section_order)).to eq([0, 1, 2])
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
      create(:subcontinuity, continuity: continuity)
      expect(continuity.ordered?).to eq(true)
    end
  end

  it "deletes sections but moves posts to sandboxes" do
    continuity = create(:continuity)
    create(:continuity, id: 3) # sandbox
    section = create(:subcontinuity, continuity: continuity)
    post = create(:post, continuity: continuity, section: section)
    perform_enqueued_jobs(only: UpdateModelJob) do
      continuity.destroy
    end
    post.reload
    expect(post.continuity_id).to eq(3)
    expect(post.section).to be_nil
    expect(Subcontinuity.find_by_id(section.id)).to be_nil
  end
end
