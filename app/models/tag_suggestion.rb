# frozen_string_literal: true

# A reader proposing a tag on someone else's post, for the post author to accept
# or decline. Declining blocks the tag on that post for every reader, not just
# the one who suggested it, until the author permits it again.
class TagSuggestion < ApplicationRecord
  MAX_PENDING_PER_USER = 20
  MAX_PENDING_PER_POST = 10

  belongs_to :post, inverse_of: :tag_suggestions, optional: false
  belongs_to :user, inverse_of: :tag_suggestions, optional: false
  belongs_to :tag, optional: true
  belongs_to :resolved_by, class_name: 'User', optional: true

  # An endorsement records a reader independently suggesting a tag the post
  # already carries but they could not see. It needs no action from the author.
  enum :status, { pending: 0, accepted: 1, rejected: 2, endorsed: 3 }

  validates :tag_type, inclusion: { in: Tag::POST_TYPES, allow_nil: true }
  validate :names_exactly_one_tag
  validate :tag_is_a_post_tag
  validate :suggester_is_not_the_author, on: :create
  validate :post_accepts_suggestions, on: :create
  validate :within_rate_limits, on: :create

  scope :ordered, -> { order(created_at: :desc) }

  # Returns [record_or_nil, outcome].
  #
  # The response must not disclose anything the suggester cannot already see:
  # "already on this post" would reveal a collapsed spoiler tagging, and
  # "already declined" would reveal the author's decision. Those collisions get
  # the same outcome to the suggester as a new suggestion.
  def self.submit(post:, user:, tag: nil, tag_type: nil, tag_name: nil, note: nil, spoiler: false, applies_from_reply_order: nil)
    # Checked first, as the endorsement below would otherwise raise on a closed post.
    return [nil, :not_accepted] unless post.allow_tag_suggestions?

    # A proposed name that already exists is a suggestion of that tag, so a
    # declined tag cannot be re-proposed by name to get past the block.
    if tag.nil? && tag_type.present? && tag_name.present?
      tag = Tag.find_by(type: tag_type, name: tag_name)
      tag_type = tag_name = nil if tag
    end

    if tag && (tagging = post.post_tags.find_by(tag: tag))
      return [nil, :already_visible] if tagging.expanded_for?(user)
      endorsement = find_by(post: post, tag: tag) ||
                    create!(post: post, user: user, tag: tag, note: note, status: :endorsed, resolved_at: Time.zone.now)
      return [endorsement, :endorsed]
    end

    # Covers a pending duplicate and a standing rejection alike.
    prior = tag ? where(post: post, tag: tag) : where(post: post, tag_id: nil, tag_type: tag_type, tag_name: tag_name)
    return [nil, :silently_deduped] if prior.exists?

    record = new(
      post: post, user: user, tag: tag, tag_type: tag_type, tag_name: tag_name,
      note: note, spoiler: spoiler, applies_from_reply_order: applies_from_reply_order,
    )
    return [record, :invalid] unless record.save

    Notification.notify_user(post.user, :tag_suggested, post: post)
    [record, :created]
  end

  def tag_display_name
    tag&.name || tag_name
  end

  def tag_display_type
    tag&.type || tag_type
  end

  # A proposed tag is created attributed to the suggester, as it would have
  # been had they tagged the post themselves.
  def accept!(resolver:)
    transaction do
      tag_record = tag || Tag.find_or_create_by!(type: tag_type, name: tag_name) { |new_tag| new_tag.user = user }
      tagging = PostTag.find_or_initialize_by(post: post, tag: tag_record)
      tagging.update!(spoiler: spoiler, applies_from_reply_order: applies_from_reply_order)
      update!(
        status: :accepted, resolved_by: resolver, resolved_at: Time.zone.now,
        tag: tag_record, tag_type: nil, tag_name: nil,
      )
    end
  end

  def reject!(resolver:)
    update!(status: :rejected, resolved_by: resolver, resolved_at: Time.zone.now)
  end

  private

  def names_exactly_one_tag
    return if tag_id.present? ^ (tag_type.present? && tag_name.present?)
    errors.add(:base, "A suggestion must name exactly one of an existing tag or a new tag name.")
  end

  def tag_is_a_post_tag
    return if tag.nil? || Tag::POST_TYPES.include?(tag.type)
    errors.add(:base, "#{tag.type} tags cannot be applied to posts.")
  end

  def suggester_is_not_the_author
    return unless post && post.user_id == user_id
    errors.add(:base, "An author must tag their own post directly.")
  end

  def post_accepts_suggestions
    return if post.nil? || post.allow_tag_suggestions?
    errors.add(:base, "This post does not accept tag suggestions.")
  end

  def within_rate_limits
    if user && TagSuggestion.pending.where(user: user).count >= MAX_PENDING_PER_USER
      errors.add(:base, "Limit of #{MAX_PENDING_PER_USER} pending suggestions per user reached.")
    end
    return unless post && TagSuggestion.pending.where(post: post).count >= MAX_PENDING_PER_POST
    errors.add(:base, "Limit of #{MAX_PENDING_PER_POST} pending suggestions per post reached.")
  end
end
