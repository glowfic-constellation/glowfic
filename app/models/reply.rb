class Reply < ActiveRecord::Base
  include Writable

  belongs_to :post, inverse_of: :replies
  attr_accessible :post, :post_id, :thread_id
  validates_presence_of :post
  audited associated_with: :post

  after_create :notify_other_authors, :destroy_draft
  after_save :update_post_timestamp
  after_destroy :destroy_subsequent_replies

  def skip_notify
    @skip_notify
  end
  def skip_notify=(val)
    @skip_notify = val
  end
  
  def skip_post_update
    @skip_post_update
  end

  def skip_post_update=(val)
    @skip_post_update = val
  end

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

  def update_post_timestamp
    return if skip_post_update
    post.skip_edited = true
    post.last_user = user
    post.last_reply = self
    post.updated_at = updated_at
    post.save
  end

  def destroy_subsequent_replies
    Reply.where('id > ?', id).where(post_id: post_id).delete_all
  end

  def destroy_draft
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
end
