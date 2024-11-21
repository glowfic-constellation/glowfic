# frozen_string_literal: true
class GalleryGroup < Tag
  def merge_with(other_tag)
    super do
      # rubocop:disable Rails/SkipsModelValidations
      their_characters = CharacterTag.where(tag: other_tag)
      their_characters.where(character_id: character_ids).delete_all
      their_characters.update_all(tag_id: self.id)

      their_galleries = GalleryTag.where(tag: other_tag)
      their_galleries.where(gallery_id: gallery_ids).delete_all
      their_galleries.update_all(tag_id: self.id)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
