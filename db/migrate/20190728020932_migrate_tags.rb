class MigrateTags < ActiveRecord::Migration[5.2]
  def up
    tag_ids = ContentWarning.all.pluck(:id) + Label.all.pluck(:id)
    post_tags = PostTag.where(tag_id: tag_ids)
    post_ids = post_tags.select(:post_id).distinct.pluck(:post_id)
    Tag.transaction do
      Post.where(:id: post_ids).each do |post|
        post.labels_list = post.labels.map(&:name)
        post.content_warnings_list = post.content_warnings.map(&:name)
      end
      post_tags.destroy_all
      Tag.where(id: tag_ids).destroy_all
    end
  end

  def down
    Tag.transaction do
      warnings = ActsAsTaggableOn::Tag.for_context(:content_warning).pluck(:name)
      warnings.each do |content_warning|
        ContentWarning.create!(name: content_warning)
      end

      labels = ActsAsTaggableOn::Tag.for_context(:label).pluck(:name)
      labels.each do |label|
        Label.create!(name: label)
      end

      Post.tagged_with((warnings + labels), any: true).each do |post|
        post.content_warning_list.each do |warning|
          PostTag.create!(post: post, warning: ContentWarning.find_by(name: warning))
        end

        post.label_list.each do |label|
          PostTag.create!(post: post, warning: ContentWarning.find_by(name: warning))
        end
      end
    end
  end
end
