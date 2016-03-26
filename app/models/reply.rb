class Reply < ActiveRecord::Base
  include Writable

  belongs_to :post, inverse_of: :replies
  attr_accessible :post, :post_id, :thread_id
  validates_presence_of :post
  audited associated_with: :post

  after_create :notify_other_authors
  after_save :update_post_timestamp
  after_destroy :destroy_subsequent_replies

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

  private

  def update_post_timestamp
    post.update_attributes(updated_at: updated_at) unless skip_post_update
  end

  def destroy_subsequent_replies
    Reply.where('id > ?', id).where(post_id: post_id).delete_all
  end

  def notify_other_authors
    post.authors.each do |author|
      next if author.id == user_id
      next unless author.email.present?
      UserMailer.post_has_new_reply(author, self).deliver
    end
  end
end
