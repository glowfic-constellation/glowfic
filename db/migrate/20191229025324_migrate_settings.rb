class MigrateSettings < ActiveRecord::Migration[5.2]
  include ActiveSupport::Inflector

  def up
    add_column :aato_tag, :description, :text unless column_exists?(:aato_tag, :description)
    Setting.all.each do |tag|
      aato_tag = ActsAsTaggableOn::Tag.create!(
        name: tag.name,
        created_at: tag.created_at,
        updated_at: tag.updated_at,
        description: tag.description
      )
      tag.character_tags.each { |char_tag| create_tagging(aato_tag, old_tagging: char_tag, type: Character) }
      tag.post_tags.each { |post_tag| create_tagging(aato_tag, old_tagging: post_tag, type: Post) }
      create_tagging(aato_tag, old_tagging: tag, type: User)
    end
    TagTag.all.each do |tag_tag|
      parent = ActsAsTaggableOn::Tag.find_by(name: tag_tag.parent_setting.name)
      child = ActsAsTaggableOn::Tag.find_by(name: tag_tag.child_setting.name)
      ActsAsTaggableOn::Tagging.create!(
        tag: parent,
        taggable_type: 'ActsAsTaggableOn::Tag',
        taggable_id: child.id,
        context: 'setting',
        created_at: tag_tag.created_at
      )
    end
    Setting.all.destroy_all
  end

  def down
    settings = ActsAsTaggableOn::Tag.for_context('setting')
    settings.each do |tag|
      user = tag.ownership_taggings.order(created_at: :asc).first.taggable
      setting = Setting.create!(name: tag.name, user: user, created_at: tag.created_at, updated_at: tag.updated_at)
      tag.taggings.where.not(taggable_type: 'ActsAsTaggableOn::Tag').each { |tagging| create_join(setting, tagging) }
    end
    ActsAsTaggableOn::Tagging.where(taggable_type: 'ActsAsTaggableOn::Tag').each do |tagging|
      parent = Setting.find_by(name: tagging.tag.name)
      child = Setting.find_by(name: tagging.taggable.name)
      TagTag.create!(
        tag_id: parent.id,
        tagged_id: child.id,
        created_at: tagging.created_at,
      )
    end
    settings.destroy_all
  end

  def create_tagging(aato_tag, old_tagging:, type:, context: 'setting')
    ActsAsTaggableOn::Tagging.create!(
      tag: aato_tag,
      taggable_type: type.to_s,
      taggable_id: old_tagging[foreign_key(type)],
      context: context,
      created_at: old_tagging.created_at
    )
  end

  def create_join(tag, tagging)
    table = constantize(tagging.taggable_type + '_' + 'tag')
    table.create!(
      foreign_key(tagging.taggable_type) => tagging.taggable_id,
      tag_id: tag.id,
      created_at: tagging.created_at,
    )
  end
end
