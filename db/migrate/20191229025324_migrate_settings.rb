class MigrateSettings < ActiveRecord::Migration[5.2]
  include ActiveSupport::Inflector

  def up
    Setting.all.each do |tag|
      aato_tag = ActsAsTaggableOn::Tag.create!(name: tag.name, created_at: tag.created_at, updated_at: tag.updated_at)
      tag.character_tags.each do |char_tag|
        create_tagging(aato_tag, old_tagging: char_tag, type: Character)
      end
      tag.post_tags.each do |post_tag|
        create_tagging(aato_tag, old_tagging: post_tag, type: Post)
      end
      tag.child_setting_tags.each do |tag_tag|
        create_tagging(aato_tag, old_tagging: tag_tag, type: Tag)
      end
      create_tagging(aato_tag, old_tagging: tag, type: User)
    end
    Setting.all.destroy_all
  end

  def down
    settings = ActsAsTaggableOn::Tag.for_context(:post_groups)
    settings.each do |tag|
      user = tag.ownership_taggings.order(created_at: :asc).first.taggable
      setting = Setting.create!(name: tag.name, user: user, created_at: tag.created_at, updated_at: tag.updated_at)
      tag.taggings.each { |tagging| create_join(setting, tagging) }
    end
    settings.destroy_all
  end

  def create_tagging(aato_tag, old_tagging:, type:, context: 'setting')
    ActsAsTaggableOn::Tagging.create!(
      tag: aato_tag,
      taggable_type: type.to_s,
      taggable_id: old_tagging[find_foreign_key(type)],
      context: context,
      created_at: old_tagging.created_at
    )
  end

  def create_join(tag, tagging)
    table = constantize(tagging.taggable_type + '_' + 'tag')
    table.create!(
      find_foreign_key(type) => tagging.taggable_id,
      tag_id: tag.id,
      created_at: tagging.created_at,
    )
  end

  def find_foreign_key(type)
    if type == Tag
      foreign_key = 'tagged_id'
    else
      foreign_key = foreign_key(type)
    end
  end
end
