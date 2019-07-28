class MigrateTags < ActiveRecord::Migration[5.2]
  def up
    character_ids = CharacterTag.all.select(:character_id).distinct.pluck(:character_id)
    Character.where(id: character_ids).each do |character|
      character.settings_list = character.settings.map(&:name)
      character.gallery_groups_list = character.gallery_groups.map(&:name)
      character.save!
    end
    drop_table :character_tags

    gallery_ids = GalleryTag.all.select(:gallery_id).distinct.pluck(:gallery_id)
    Gallery.where(id: gallery_ids).each do |gallery|
      gallery.gallery_groups_list = gallery.gallery_groups.map(&:name)
    end
    drop_table :gallery_tags

    post_ids = PostTag.all.select(:post_id).distinct.pluck(:post_id)
    Post.where(:id: post_ids).each do |post|
      post.settings_list = post.settings.map(&:name)
      post.labels_list = post.labels.map(&:name)
      post.content_warnings_list = post.content_warnings.map(&:name)
    end
    drop_table :post_tags
    drop_table :tags
  end

  def down
    create_table :character_tags do |t|
      t.integer :character_id, null: false
      t.integer :tag_id, null: false
      t.timestamps null: true
    end
    add_index :character_tags, :character_id
    add_index :character_tags, :tag_id

    create_table :gallery_tags do |t|
      t.integer :gallery_id, null: false
      t.integer :tag_id, null: false
      t.timestamps null: true
    end
    add_index :gallery_tags, :gallery_id
    add_index :gallery_tags, :tag_id

    create_table :post_tags do |t|
      t.integer :post_id, null: false
      t.integer :tag_id, null: false
      t.boolean :suggested, default: false
      t.timestamps null: true
    end
    add_index :post_tags, :post_id
    add_index :post_tags, :tag_id

    create_table :tags do |t|
      t.integer :user_id, null: false
      t.citext :name, null: false
      t.string :type
      t.text :description
      t.boolean :owned, default: false
      t.timestamps null: true
    end
    add_index :tags, :name
    add_index :tags, :type

    ApplicationRecord.transaction do
      ActsAsTaggableOn::Tag.for_context(:setting).pluck(:name).each do |setting|
        Setting.create!(name: setting)
      end

      ActsAsTaggableOn::Tag.for_context(:gallery_group).pluck(:name).each do |gallery_group|
        GalleryGroup.create!(name: gallery_group)
      end

      ActsAsTaggableOn::Tag.for_context(:content_warning).pluck(:name).each do |content_warning|
        ContentWarning.create!(name: content_warning)
      end

      ActsAsTaggableOn::Tag.for_context(:label).pluck(:name).each do |label|
        Label.create!(name: label)
      end
    end
  end
end
