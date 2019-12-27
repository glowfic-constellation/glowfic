class MigrateGalleryGroups < ActiveRecord::Migration[5.2]
  def up
    tags = Tag.where(type: 'GalleryGroup')
    character_tags = CharacterTag.where(tag: tags)
    gallery_tags = GalleryTag.where(tag: tags)
    character_ids = character_tags.select(:character_id).distinct.pluck(:character_id)
    gallery_ids = gallery_tags.select(:gallery_id).distinct.pluck(:gallery_id)
    Tag.transaction do
      tags.each do |tag|
        ActsAsTaggableOn::Tag.create!(name: tag.name, created_at: tag.created_at, updated_at: tag.updated_at)
      end
      Character.where(id: character_ids).each do |character|
        local_tags = character_tags.where(character: character).pluck(:tag_id)
        local_tags.each do |tag_id|
          tag = Tag.find_by(id: tag_id)
          character.user.tag(character, with: tag.name, on: :gallery_groups, skip_save: true)
        end
        character.save!
      end
      Gallery.where(id: gallery_ids).each do |gallery|
        local_tags = gallery_tags.where(gallery: gallery).pluck(:tag_id)
        local_tags.each do |tag_id|
          tag = Tag.find_by(id: tag_id)
          gallery.user.tag(gallery, with: tag.name, on: :gallery_groups, skip_save: true)
        end
        gallery.save!
      end
      character_tags.destroy_all
      gallery_tags.destroy_all
      tags.destroy_all
    end
  end

  def down
    gallery_groups = ActsAsTaggableOn::Tag.for_context(:gallery_groups)
    gallery_groups.each do |group|
      user = group.taggings.order(created_at: :asc).first.tagger
      GalleryGroup.create!(name: group.name, user: user, created_at: group.created_at, updated_at: group.updated_at)
    end

    character_taggings = Character.tagged_with(gallery_groups, any: true)
    character_taggings.each do |character|
      character.gallery_group_list.each do |group|
        CharacterTag.create!(character: character, tag: GalleryGroup.find_by(name: group))
      end
    end
    character_taggings.destroy_all

    gallery_taggings = Gallery.tagged_with(gallery_groups, any: true)
    gallery_taggings.each do |gallery|
      gallery.gallery_group_list.each do |group|
        GalleryTag.create!(gallery: gallery, tag: GalleryGroup.find_by(name: group))
      end
    end
    gallery_taggings.destroy_all

    gallery_groups.destroy_all
  end
end
