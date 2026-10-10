# frozen_string_literal: true
class PostTag < ApplicationRecord
  belongs_to :post, inverse_of: :post_tags, optional: false
  belongs_to :tag, inverse_of: :post_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :setting, foreign_key: :tag_id, inverse_of: :post_tags, optional: true
  belongs_to :content_warning, foreign_key: :tag_id, inverse_of: :post_tags, optional: true
  belongs_to :label, foreign_key: :tag_id, inverse_of: :post_tags, optional: true

  validates :post, uniqueness: { scope: :tag }
  validates :applies_from_reply_order, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validate :content_warning_not_spoilered

  # A spoiler tagging is shown collapsed until the reader expands it, unless
  # they have opted to see spoiler tags or can edit the post.
  def expanded_for?(user)
    return true unless spoiler?
    return false if user.nil?
    user.reveal_spoiler_tags? || post.user_id == user.id || user.has_permission?(:edit_posts)
  end

  private

  def content_warning_not_spoilered
    return unless spoiler? && tag.is_a?(ContentWarning)
    errors.add(:spoiler, "cannot be set on a content warning, which must be visible before the content it warns about")
  end
end
