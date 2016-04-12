class ReplyDraft < ActiveRecord::Base
  include Writable

  belongs_to :post, inverse_of: :reply_drafts
  validates_presence_of :post, :user
  attr_accessible :post, :post_id

  def self.draft_for(post_id, user_id)
    self.where(post_id: post_id, user_id: user_id).first
  end

  def self.draft_reply_for(post, user)
    return unless draft = draft_for(post.id, user.id)
    Reply.new(draft.attributes.except(:id, :created_at, :updated_at))
  end
end
