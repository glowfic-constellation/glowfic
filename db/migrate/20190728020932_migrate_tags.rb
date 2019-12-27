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
        local_tags = post_tags.where(post: post).pluck(:tag_id)
        local_tags.each do |tag_id|
          tag = Tag.where(id: tag_id)
          type = tag.is_a?(Label) ? :labels : :content_warnings
          user = tag.posts.order(created_at: :asc, id: :asc).first == post ? tag.user : post.user
          user.tag(post, with: tag.name, on: type, skip_save: true)
        end
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
