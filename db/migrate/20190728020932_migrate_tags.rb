class MigrateTags < ActiveRecord::Migration[5.2]
  include ActiveSupport::Inflector

  def up
    add_column :aato_tag, :description, :text unless column_exists?(:aato_tag, :description)
    add_column :aato_tag, :type, :string unless column_exists?(:aato_tag, :type)
    tags = Tag.where(type: 'Label').or(Tag.where(type: 'ContentWarning'))
    tags.each do |tag|
      aato_tag = ActsAsTaggableOn::Tag.create!(
        name: tag.name,
        created_at: tag.created_at,
        updated_at: tag.updated_at,
        description: tag.description
      )
      tag.post_tags.each { |post_tag| create_tagging(aato_tag, old_tagging: post_tag, type: Post, context: tableize(tag.class.name)) }
      create_tagging(aato_tag, old_tagging: tag, type: User)
    end
    Setting.all.destroy_all
  end

  def down
    ActsAsTaggableOn::Tag.for_context(:labels).each do |tag|
      user = tag.child_taggings.where(taggable_type: 'User').order(created_at: :asc).first.taggable
      new_tag = Label.create!(name: tag.name, user: user, created_at: tag.created_at, updated_at: tag.updated_at, description: tag.description)
      tag.taggings.each { |tagging| create_join(new_tag, tagging) }
    end
    ActsAsTaggableOn::Tag.for_context(:content_warnings).each do |tag|
      user = tag.child_taggings.where(taggable_type: 'User').order(created_at: :asc).first.taggable
      new_tag = ContentWarning.create!(name: tag.name, user: user, created_at: tag.created_at, updated_at: tag.updated_at, description: tag.description)
      tag.taggings.each { |tagging| create_join(new_tag, tagging) }
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
