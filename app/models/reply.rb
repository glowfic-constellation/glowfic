class Reply < ActiveRecord::Base
  include Writable

  belongs_to :post, inverse_of: :replies
  attr_accessible :post, :post_id
  validates_presence_of :post
  audited associated_with: :post

  after_save :update_post_timestamp
  after_destroy :destroy_subsequent_replies

  private

  def update_post_timestamp
    post.update_attributes(updated_at: updated_at)
  end

  def destroy_subsequent_replies
    Reply.where('id > ?', id).where(post_id: post_id).delete_all
  end
end
