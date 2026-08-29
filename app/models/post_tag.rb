# frozen_string_literal: true
class PostTag < ApplicationRecord
  belongs_to :post, inverse_of: :post_tags, optional: false
  belongs_to :tag, inverse_of: :post_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :setting, foreign_key: :tag_id, inverse_of: :post_tags, optional: true
  belongs_to :content_warning, foreign_key: :tag_id, inverse_of: :post_tags, optional: true
  belongs_to :label, foreign_key: :tag_id, inverse_of: :post_tags, optional: true

  validates :post, uniqueness: { scope: :tag }
  validates :reveal_after_reply_order, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validate :content_warnings_are_not_spoilerable

  scope :spoilered, -> { where(spoiler: true) }
  scope :unspoilered, -> { where(spoiler: false) }

  # Spoilered taggings are excluded from tag -> post listings entirely, so a
  # spoilered post does not appear under that tag. This is the one part of the
  # feature the client cannot be trusted with.
  scope :for_reverse_lookup, -> { unspoilered }

  # Whether the tagging is displayed already expanded. Reveal is otherwise a
  # reader action: reading position plays no part.
  def expanded_for?(user)
    return true unless spoiler?
    return false if user.nil?
    return true if user.reveal_spoiler_tags?
    return true if post.user_id == user.id
    user.has_permission?(:edit_posts)
  end

  # Descriptive rather than a gate: the reply from which the tag applies.
  def applies_from_reply_order
    reveal_after_reply_order
  end

  private

  def content_warnings_are_not_spoilerable
    return unless spoiler?
    return unless tag.is_a?(ContentWarning)
    errors.add(:spoiler, "cannot be set on a content warning, which must be visible before the content it warns about")
  end
end
