RSpec.describe WranglingAssignment do
  let(:wrangler) { create(:wrangler_user) }

  describe ".scope_ids_for" do
    it "is empty for a user with no assignments" do
      expect(WranglingAssignment.scope_ids_for(wrangler)).to be_empty
      expect(WranglingAssignment.scope_ids_for(nil)).to be_empty
    end

    it "includes descendants but not ancestors of an assigned setting" do
      parent = create(:setting)
      child = create(:setting)
      grandchild = create(:setting)
      Tag::MetaTag.create!(parent_tag: parent, child_tag: child)
      Tag::MetaTag.create!(parent_tag: child, child_tag: grandchild)
      WranglingAssignment.create!(user: wrangler, setting: child)

      expect(WranglingAssignment.scope_ids_for(wrangler)).to match_array([child.id, grandchild.id])
    end

    it "excludes settings reachable only through a suggested edge" do
      parent = create(:setting)
      child = create(:setting)
      Tag::MetaTag.create!(parent_tag: parent, child_tag: child, suggested: true)
      WranglingAssignment.create!(user: wrangler, setting: parent)

      expect(WranglingAssignment.scope_ids_for(wrangler)).to eq([parent.id])
      expect(parent.child_settings).to be_empty
    end

    it "is memoized on the user" do
      WranglingAssignment.create!(user: wrangler, setting: create(:setting))
      expect(WranglingAssignment).to receive(:scope_ids_for).once.and_call_original
      2.times { wrangler.wrangling_scope_ids }
    end
  end

  describe ".reassign_for_merge" do
    let(:loser) { create(:setting) }
    let(:winner) { create(:setting) }

    it "moves the assignment onto the surviving setting and notifies" do
      WranglingAssignment.create!(user: wrangler, setting: loser)

      WranglingAssignment.reassign_for_merge(source: loser, target: winner)

      expect(wrangler.reload.wrangled_settings).to eq([winner])
      expect(Notification.where(user: wrangler, notification_type: :wrangling_scope_merged)).to be_present
    end

    it "notifies the wranglers of both settings" do
      other = create(:wrangler_user)
      WranglingAssignment.create!(user: wrangler, setting: loser)
      WranglingAssignment.create!(user: other, setting: winner)

      WranglingAssignment.reassign_for_merge(source: loser, target: winner)

      expect(winner.reload.wranglers).to match_array([wrangler, other])
      expect(Notification.where(notification_type: :wrangling_scope_merged).count).to eq(2)
    end

    it "drops an assignment the wrangler already holds on the survivor" do
      WranglingAssignment.create!(user: wrangler, setting: loser)
      WranglingAssignment.create!(user: wrangler, setting: winner)

      expect { WranglingAssignment.reassign_for_merge(source: loser, target: winner) }
        .to change { WranglingAssignment.count }.by(-1)
    end

    it "runs as part of a synonym merge" do
      WranglingAssignment.create!(user: wrangler, setting: loser)
      winner.merge_as_synonym(loser)
      expect(wrangler.reload.wrangled_settings).to eq([winner])
    end
  end
end
