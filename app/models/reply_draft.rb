class ReplyDraft < ApplicationRecord
  include Writable

  belongs_to :post, inverse_of: :reply_drafts, optional: false

  def self.draft_for(post_id, user_id)
    self.where(post_id: post_id, user_id: user_id).first
  end

  def self.draft_reply_for(post, user)
    return unless (draft = draft_for(post.id, user.id))
    ReplyDraft.reply_from_draft(draft)
  end

  def self.reply_from_draft(draft)
    Reply.new(draft.attributes.except('id', 'created_at', 'updated_at'))
  end
end
