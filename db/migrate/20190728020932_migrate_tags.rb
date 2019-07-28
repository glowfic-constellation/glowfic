class MigrateTags < ActiveRecord::Migration[5.2]
  def up
    tags = Tag.where(type: 'Label').or(Tag.where(type: 'ContentWarning'))
    post_tags = PostTag.where(tag: tags)
    post_ids = post_tags.select(:post_id).distinct.pluck(:post_id)
    Tag.transaction do
      tags.each do |tag|
        ActsAsTaggableOn::Tag.create!(name: tag.name, created_at: tag.created_at, updated_at: tag.updated_at)
      end
      Post.where(id: post_ids).each do |post|
        local_ids = post_tags.where(post: post).pluck(:tag_id)
        post.label_list = Label.where(id: local_ids).pluck(:name)
        post.content_warning_list = ContentWarning.where(id: local_ids).pluck(:name)
        post.save!
      end
      post_tags.destroy_all
      tags.destroy_all
    end
  end

  def down
    Tag.transaction do
      warnings = ActsAsTaggableOn::Tag.for_context(:content_warnings)
      warnings.each do |warning|
        ContentWarning.create!(name: warning.name, created_at: warning.created_at, updated_at: warning.updated_at)
      end

      labels = ActsAsTaggableOn::Tag.for_context(:labels)
      labels.each do |label|
        Label.create!(name: label.name, created_at: label.created_at, updated_at: label.updated_at)
      end

      Post.tagged_with((warnings + labels), any: true).each do |post|
        post.content_warning_list.each do |warning|
          PostTag.create!(post: post, tag: ContentWarning.find_by(name: warning))
        end

        post.label_list.each do |label|
          PostTag.create!(post: post, tag: Label.find_by(name: label))
        end
      end
    end
  end
end
