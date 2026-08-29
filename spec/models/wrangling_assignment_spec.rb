RSpec.describe WranglingAssignment do
  let(:wrangler) { create(:wrangler_user) }

  describe ".scope_ids_for" do
    it "is empty for a user with no assignments" do
      expect(WranglingAssignment.scope_ids_for(wrangler)).to be_empty
      expect(WranglingAssignment.scope_ids_for(nil)).to be_empty
    end

    it "includes descendants of an assigned setting" do
      parent = create(:setting)
      child = create(:setting)
      grandchild = create(:setting)
      Tag::MetaTag.create!(parent_tag: parent, child_tag: child)
      Tag::MetaTag.create!(parent_tag: child, child_tag: grandchild)
      WranglingAssignment.create!(user: wrangler, setting: parent)

      expect(WranglingAssignment.scope_ids_for(wrangler)).to match_array([parent.id, child.id, grandchild.id])
    end

    it "excludes descendants reachable only through a suggested edge" do
      parent = create(:setting)
      child = create(:setting)
      Tag::MetaTag.create!(parent_tag: parent, child_tag: child, suggested: true)
      WranglingAssignment.create!(user: wrangler, setting: parent)

      expect(WranglingAssignment.scope_ids_for(wrangler)).to eq([parent.id])
      expect(parent.child_settings).to be_empty
    end

    it "memoizes the resolved scope on the user" do
      setting = create(:setting)
      WranglingAssignment.create!(user: wrangler, setting: setting)
      wrangler.wrangling_scope_ids

      expect(count_queries { 5.times { wrangler.wrangling_scope_ids } }).to be_empty
    end

    it "does not include ancestors of an assigned setting" do
      parent = create(:setting)
      child = create(:setting)
      Tag::MetaTag.create!(parent_tag: parent, child_tag: child)
      WranglingAssignment.create!(user: wrangler, setting: child)

      expect(WranglingAssignment.scope_ids_for(wrangler)).to eq([child.id])
    end
  end

  describe ".reassign_for_merge" do
    it "moves the assignment onto the surviving setting and notifies" do
      loser = create(:setting)
      winner = create(:setting)
      WranglingAssignment.create!(user: wrangler, setting: loser)

      WranglingAssignment.reassign_for_merge(source: loser, target: winner)

      expect(wrangler.reload.wrangled_settings).to eq([winner])
      expect(Notification.where(user: wrangler, notification_type: :wrangling_scope_merged)).to be_present
    end

    it "collapses two wranglers onto the survivor and notifies both" do
      other = create(:wrangler_user)
      loser = create(:setting)
      winner = create(:setting)
      WranglingAssignment.create!(user: wrangler, setting: loser)
      WranglingAssignment.create!(user: other, setting: winner)

      WranglingAssignment.reassign_for_merge(source: loser, target: winner)

      expect(winner.reload.wranglers).to match_array([wrangler, other])
      expect(Notification.where(notification_type: :wrangling_scope_merged).count).to eq(2)
    end

    it "drops a duplicate rather than violating uniqueness" do
      loser = create(:setting)
      winner = create(:setting)
      WranglingAssignment.create!(user: wrangler, setting: loser)
      WranglingAssignment.create!(user: wrangler, setting: winner)

      expect { WranglingAssignment.reassign_for_merge(source: loser, target: winner) }
        .to change { WranglingAssignment.count }.by(-1)
    end

    it "runs through a synonym merge" do
      loser = create(:setting)
      winner = create(:setting)
      WranglingAssignment.create!(user: wrangler, setting: loser)

      winner.merge_as_synonym(loser)

      expect(wrangler.reload.wrangled_settings).to eq([winner])
    end
  end

  describe "permissions" do
    it "lets a wrangler wrangle an assigned setting but not an unassigned one" do
      assigned = create(:setting)
      unassigned = create(:setting)
      WranglingAssignment.create!(user: wrangler, setting: assigned)

      expect(assigned.wrangleable_by?(wrangler)).to eq(true)
      expect(unassigned.wrangleable_by?(wrangler)).to eq(false)
    end

    it "lets a wrangler wrangle a label co-tagged with an assigned setting" do
      setting = create(:setting)
      label = create(:label)
      create(:post, settings: [setting], labels: [label])
      WranglingAssignment.create!(user: wrangler, setting: setting)

      expect(label.wrangleable_by?(wrangler)).to eq(true)
      expect(create(:label).wrangleable_by?(wrangler)).to eq(false)
    end

    it "gives admins global wrangling without assignments" do
      admin = create(:admin_user)
      expect(create(:content_warning).wrangleable_by?(admin)).to eq(true)
    end

    it "denies non-wranglers" do
      expect(create(:setting).wrangleable_by?(create(:user))).to eq(false)
      expect(create(:setting).wrangleable_by?(create(:mod_user))).to eq(false)
    end

    it "gates hierarchy editing on wrangling rights" do
      setting = create(:setting)
      expect(setting.hierarchy_editable_by?(setting.user)).to eq(false)
      WranglingAssignment.create!(user: wrangler, setting: setting)
      expect(setting.hierarchy_editable_by?(wrangler)).to eq(true)
    end

    it "does not allow hierarchy editing on flat tag types" do
      warning = create(:content_warning)
      expect(warning.hierarchy_editable_by?(create(:admin_user))).to eq(false)
    end
  end
end
