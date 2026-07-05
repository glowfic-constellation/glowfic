# frozen_string_literal: true
class AccessCircle < Tag
  validates :name, uniqueness: { scope: [:type, :user] }

  scope :visible, -> { where(owned: false) }

  def visible_to?(user)
    return false if user.nil?
    return true unless owned?
    return true if user.admin?
    user.id == user_id
  end

  def self.post_counts(circles, user)
    visible_posts = circles.joins(:posts).merge(Post.visible_to(user)).pluck('posts.id')
    sql = sanitize_sql_array(['LEFT JOIN post_tags ON post_tags.tag_id = tags.id AND post_tags.post_id IN (?)', visible_posts])
    circles.joins(sql).group('tags.id').pluck('tags.id, count(post_tags.id)').to_h
  end
end
