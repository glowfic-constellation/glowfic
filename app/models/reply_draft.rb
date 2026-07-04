# frozen_string_literal: true
class ReplyDraft < ApplicationRecord
  include Writable

  belongs_to :post, inverse_of: :reply_drafts, optional: false

  validates :post, uniqueness: { scope: :user }
  validate :scheduled_at_in_future

  scope :scheduled, -> { where.not(scheduled_at: nil) }

  scope :due_for_posting, -> { where('reply_drafts.scheduled_at IS NOT NULL AND reply_drafts.scheduled_at <= ?', Time.zone.now) }

  def self.draft_for(post_id, user_id)
    self.find_by(post_id: post_id, user_id: user_id)
  end

  def self.draft_reply_for(post, user)
    return unless (draft = draft_for(post.id, user.id))
    ReplyDraft.reply_from_draft(draft)
  end

  def self.reply_from_draft(draft)
    Reply.new(draft.attributes.except('id', 'created_at', 'updated_at', 'scheduled_at'))
  end

  # True while the draft is queued to be posted at a future time.
  def scheduled?
    scheduled_at.present?
  end

  # Promotes the queued draft into an actual reply ("tag"). Saving the reply
  # destroys this draft via Reply's after_create :destroy_draft callback.
  def post_as_reply!
    reply = ReplyDraft.reply_from_draft(self)
    reply.save!
    reply
  end

  private

  def scheduled_at_in_future
    return unless scheduled_at_changed?
    return if scheduled_at.blank?
    errors.add(:scheduled_at, "must be in the future") if scheduled_at <= Time.zone.now
  end
end
