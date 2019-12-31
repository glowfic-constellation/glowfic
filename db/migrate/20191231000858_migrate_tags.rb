class MigrateTags < ActiveRecord::Migration[5.2]
  include ActiveSupport::Inflector

  def up
    create_table :taggings do |t|
      t.references :tag, type: :int
      t.references :taggable, polymorphic: true, type: :int
      t.references :tagger, polymorphic: true, type: :int

      t.string :context, limit: 128

      t.datetime :created_at
    end

    add_column :tags, :taggings_count, :integer, default: 0

    Tag.where(owned: true).each do |tag|
      ActsAsTaggableOn::Tagging.create!(tag: tag, taggable_id: tag.user_id, taggable_type: 'User', context: 'settings')
    end

    PostTag.all.each { |tagging| create_tagging(tagging, Post) }
    CharacterTag.all.each { |tagging| create_tagging(tagging, Character) }
    GalleryTag.all.each { |tagging| create_tagging(tagging, Gallery) }
    TagTag.all.each { |tagging| create_tagging(tagging, Setting) }

    drop_table :post_tags
    drop_table :character_tags
    drop_table :gallery_tags
    drop_table :tag_tags
    remove_column :tags, :user_id
    remove_column :tags, :owned

    ActsAsTaggableOn::Tag.reset_column_information
    ActsAsTaggableOn::Tag.find_each do |tag|
      ActsAsTaggableOn::Tag.reset_counters(tag.id, :taggings)
    end
  end

  def down
    add_column :tags, :user_id, :integer
    add_column :tags, :owned, :boolean

    ActsAsTaggableOn::Tagging.where(taggable_type: 'User').each do |tagging|
      tagging.tag.update!(user_id: tagging.taggable_id, owned: true)
      tagging.destroy!
    end

    Tag.where(user_id: nil).each do |tag|
      tag.update(user: Tag.tagging.first.user, owned: false)
    end

    new_table(:post_tags, :post_id, true)
    new_table(:character_tags, :character_id, false)
    new_table(:gallery_tags, :gallery_id, false)
    new_table(:tag_tags, :tagged_id, true)

    ActsAsTaggableOn::Tagging.all.each do |tagging|
      create_join(tagging)
    end

    drop_table :taggings
    remove_column :tags, :taggings_count
  end

  def create_tagging(tagging, type)
    tag = Tag.find_by(id: tagging.tag_id)
    ActsAsTaggableOn::Tagging.create!(
      tag_id: tagging.tag_id,
      taggable_type: type.to_s,
      taggable_id: tagging[find_foreign_key_for(type)],
      context: tableize(tag.class.to_s),
      created_at: tagging.created_at,
    )
  end

  def create_join(tagging)
    find_table_for(tagging.taggable_type).create!(
      find_foreign_key_for(tagging.taggable_type) => tagging.taggable_id,
      tag_id: tagging.tag_id,
      created_at: tagging.created_at,
    )
  end

  def find_foreign_key_for(type)
    [Setting, 'Setting'].include?(type) ? :tagged_id : foreign_key(type)
  end

  def find_table_for(type)
    type == 'Setting' ? TagTag : constantize(classify(type + '_tags'))
  end

  def new_table(table_name, key, suggested)
    create_table table_name do |t|
      t.integer key, null: false
      t.integer :tag_id, null: false
      t.boolean :suggested, default: false if suggested
      t.timestamps null: true
      t.index :tag_id
      t.index key
    end
  end
end
