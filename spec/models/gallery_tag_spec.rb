RSpec.describe GalleryTag do
  describe "callbacks" do
    context "when gallery group added to gallery" do
      it "does not add to other users' characters" do
        group = create(:gallery_group)
        character = create(:character, gallery_groups: [group])

        gallery = create(:gallery)
        gallery.gallery_groups << group
        gallery.save!
        expect(character.reload.galleries).to be_empty
      end

      it "does not add to a character twice" do
        # tests a manually-attached character1
        # and a double-grouped character2
        group = create(:gallery_group)
        group2 = create(:gallery_group)
        user = create(:user)
        character1 = create(:character, user: user, gallery_groups: [group])
        character2 = create(:character, user: user, gallery_groups: [group, group2])

        gallery = create(:gallery, user: user, characters: [character1])
        gallery.gallery_groups << group
        gallery.save!
        gallery.reload

        aggregate_failures do
          expect(gallery.characters).to match_array([character1, character2])
          expect(gallery.characters_galleries.find_by(character_id: character1.id)).not_to be_added_by_group
          expect(gallery.characters_galleries.find_by(character_id: character2.id)).to be_added_by_group
        end

        gallery.gallery_groups << group2
        gallery.save!
        gallery.reload

        aggregate_failures do
          expect(gallery.characters).to match_array([character1, character2])
          expect(gallery.characters_galleries.find_by(character_id: character1.id)).not_to be_added_by_group
          expect(gallery.characters_galleries.find_by(character_id: character2.id)).to be_added_by_group
        end
      end

      it "adds galleries to given group", :aggregate_failures do
        group = create(:gallery_group)
        user = create(:user)
        character1 = create(:character, user: user, gallery_groups: [group])
        character2 = create(:character, user: user, gallery_groups: [group])

        gallery = create(:gallery, user: user)
        gallery.gallery_groups << group
        gallery.save!
        gallery.reload

        expect(gallery.characters).to match_array([character1, character2])
        expect(gallery.characters_galleries.map(&:added_by_group?)).to eq([true, true])
      end
    end

    it "does right things when gallery group removed from gallery" do
      # does not touch unrelated characters
      # does not touch characters that have been otherwise tethered
      # removes from characters that are not otherwise tethered
      group = create(:gallery_group)
      user = create(:user)
      other_character = create(:character, user: user)
      gallery = create(:gallery, user: user, gallery_groups: [group], characters: [other_character])
      character_auto = create(:character, user: user, gallery_groups: [group])
      character_both = create(:character, user: user, gallery_groups: [group])
      gallery.reload
      gallery.characters_galleries.find_by(character_id: character_both.id).update!(added_by_group: false)

      aggregate_failures do
        expect(gallery.characters).to match_array([other_character, character_auto, character_both])
        expect(gallery.characters_galleries.find_by(character_id: character_auto.id)).to be_added_by_group
      end

      gallery.update!(gallery_groups: [])
      gallery.reload

      aggregate_failures do
        expect(gallery.characters).to match_array([other_character, character_both])
        expect(gallery.characters_galleries.find_by(character_id: character_both.id)).not_to be_added_by_group
      end
    end

    it "does not destroy gallery groups when destroyed" do
      group = create(:gallery_group)
      gallery = create(:gallery, gallery_groups: [group])
      other = create(:gallery, gallery_groups: [group])
      gallery.reload
      other.reload

      aggregate_failures do
        expect(gallery.gallery_groups).to match_array([group])
        expect(other.gallery_groups).to match_array([group])
      end

      gallery.destroy!
      group.reload

      expect(other.reload.gallery_groups).to match_array([group])
    end
  end
end
