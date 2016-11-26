class Reply < ActiveRecord::Base
  include Writable
  include PgSearch

  belongs_to :post, inverse_of: :replies
  attr_accessible :post, :post_id, :thread_id
  validates_presence_of :post, :user
  validate :author_can_write_in_post, on: :create
  audited associated_with: :post

  after_create :notify_other_authors, :destroy_draft, :update_active_char, :update_post
  before_update :delete_view_cache
  after_update :update_post
  after_destroy :update_last_reply, :delete_view_cache

  attr_accessor :skip_notify, :skip_post_update, :is_import

  pg_search_scope(
    :search,
    against: %i(content),
    using: {tsearch: { dictionary: "english" } }
  )

  def post_page(per=25)
    per_page = per > 0 ? per : post.replies.count
    index = post.replies.order('id asc').to_a.index(self)
    return 1 unless index.present?
    (index / per_page) + 1
  end

  def last_updated
    updated_at
  end

  private

  def update_post
    return if skip_post_update
    post.last_user = user
    post.last_reply = self
    post.tagged_at = updated_at
    post.status = Post::STATUS_ACTIVE if post.on_hiatus?
    post.save
  end

  def view_cache_key
    ActiveSupport::Cache.expand_cache_key(self, :views)
  end

  def delete_view_cache
    # don't rely on GC in Redis to get rid of these keys
    Rails.cache.delete(view_cache_key)
  end

  def update_active_char
    return if is_import
    user.update_attributes(:active_character => character)
  end

  def destroy_subsequent_replies
    Reply.where('id > ?', id).where(post_id: post_id).delete_all
    self.update_last_reply
  end

  def update_last_reply
    return if skip_post_update
    return unless post.replies.where('id >= ?', id).empty? # return unless needs to update last reply (this is destroyed, this is the last reply)
    post.last_reply = previous_reply
    post.last_user = (previous_reply || post).user
    post.tagged_at = (previous_reply || post).last_updated
    post.save
  end

  def destroy_draft
    return if is_import
    ReplyDraft.draft_for(post_id, user_id).try(:destroy)
  end

  def notify_other_authors
    return if skip_notify
    return if (previous_reply || post).user_id == user_id
    post.authors.each do |author|
      next if author.id == user_id
      next unless author.email.present?
      next unless author.email_notifications?
      UserMailer.post_has_new_reply(author, self).deliver
    end
  end

  def previous_reply
    @prev ||= post.replies.where('id < ?', id).order('id desc').first
  end

  def author_can_write_in_post
    return unless post && user
    errors.add(:user, 'is not a valid continuity author') unless user.writes_in?(post.board)
    return unless post.authors_locked?
    errors.add(:post, 'is not a valid post author') unless post.author_ids.include?(user_id)
  end
end
