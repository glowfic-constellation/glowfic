RSpec.describe CharacterTag do
  describe "callbacks" do
    let(:user) { create(:user) }
    let(:group) { create(:gallery_group) }
    let(:gallery) { create(:gallery, gallery_groups: [group], user: user) }

    context "when gallery group added to character" do
      it "does not add other users' galleries" do
        gallery

        character = create(:character)
        character.update!(gallery_groups: [group])
        expect(character.reload.galleries).to match_array([])
      end

      it "does not add a gallery twice" do
        # tests a manually-attached gallery1
        # and a double-grouped gallery2
        group2 = create(:gallery_group)
        gallery1 = create(:gallery, user: user, gallery_groups: [group])
        gallery2 = create(:gallery, user: user, gallery_groups: [group, group2])

        character = create(:character, user: user, galleries: [gallery1])
        character.update!(gallery_groups: [group])
        character.reload
        expect(character.galleries).to match_array([gallery1, gallery2])
        expect(character.characters_galleries.find_by(gallery_id: gallery1.id)).not_to be_added_by_group
        expect(character.characters_galleries.find_by(gallery_id: gallery2.id)).to be_added_by_group

        character.update!(gallery_groups: [group2])
        character.reload
        expect(character.galleries).to match_array([gallery1, gallery2])
        expect(character.characters_galleries.find_by(gallery_id: gallery1.id)).not_to be_added_by_group
        expect(character.characters_galleries.find_by(gallery_id: gallery2.id)).to be_added_by_group
      end

      it "adds galleries from given group" do
        gallery1 = create(:gallery, user: user, gallery_groups: [group])
        gallery2 = create(:gallery, user: user, gallery_groups: [group])

        character = create(:character, user: user)
        character.update!(gallery_groups: [group])
        character.reload
        expect(character.galleries).to match_array([gallery1, gallery2])
        expect(character.characters_galleries.map(&:added_by_group?)).to eq([true, true])
      end
    end

    it "does right things when gallery group removed from character" do
      # does not touch unrelated galleries
      # does not touch galleries that have been otherwise tethered
      # removes galleries that are not otherwise tethered
      other_gallery = create(:gallery, user: user)
      character = create(:character, user: user, gallery_groups: [group], galleries: [other_gallery])
      gallery_auto = gallery
      gallery_both = create(:gallery, user: user, gallery_groups: [group])
      character.reload
      character.characters_galleries.find_by(gallery_id: gallery_both.id).update!(added_by_group: false)
      expect(character.galleries).to match_array([other_gallery, gallery_auto, gallery_both])
      expect(character.characters_galleries.find_by(gallery_id: gallery_auto.id)).to be_added_by_group

      character.update!(gallery_groups: [])
      character.reload
      expect(character.galleries).to match_array([other_gallery, gallery_both])
      expect(character.characters_galleries.find_by(gallery_id: gallery_both.id)).not_to be_added_by_group
    end

    it "does not destroy gallery groups when destroyed" do
      character = create(:character, gallery_groups: [group])
      other = create(:character, gallery_groups: [group])
      character.reload
      other.reload
      expect(character.gallery_groups).to match_array([group])
      expect(other.gallery_groups).to match_array([group])

      Audited.audit_class.as_user(character.user) { character.destroy! }
      group.reload
      expect(other.reload.gallery_groups).to match_array([group])
    end
  end
end
