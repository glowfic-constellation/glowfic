# frozen_string_literal: true
class Skin < ApplicationRecord
  audited

  belongs_to :user, inverse_of: :skins, optional: false
  belongs_to :approved_by, class_name: 'User', inverse_of: false, optional: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :css, length: { maximum: Glowfic::CssSanitizer::MAX_LENGTH }

  before_save :recompute_derived

  scope :ordered, -> { order(name: :asc, id: :asc) }
  # Public skins safe to surface in the gallery: either harmless, or an approved
  # dangerous skin (approved_at is only set while it still matches the CSS).
  scope :listed, -> { where(public: true).where('NOT dangerous OR approved_at IS NOT NULL') }
  # Dangerous, unapproved skins that affect other readers (shared publicly or
  # set as a post's recommended skin) and so are waiting on a moderator.
  scope :pending_review, lambda {
    where(dangerous: true, approved_at: nil)
      .where('skins.public OR skins.id IN (?)', Post.where.not(skin_id: nil).select(:skin_id))
  }

  def editable_by?(user)
    return false unless user
    user_id == user.id
  end

  def visible_to?(user)
    return true if public
    return false unless user
    user_id == user.id
  end

  # A copy another user can keep and tweak as their own private skin.
  def fork_for(user)
    Skin.new(user: user, name: "#{name} (copy)", description: description, css: css)
  end

  def css_digest
    Digest::SHA256.hexdigest(css.to_s)
  end

  # Does the CSS want anything the safe tier strips for security reasons? Uses
  # the cached `dangerous` column for saved, unchanged records (set in
  # recompute_derived); computes live otherwise so it is correct before save.
  def dangerous?
    return self[:dangerous] if persisted? && !css_changed?

    Glowfic::CssSanitizer.dangerous?(css)
  end

  # Approval is valid only while it still matches the current CSS. recompute_derived
  # clears it on edit, so in the database approved_at is set iff this holds.
  def approved?
    approved_at.present? && approved_digest == css_digest
  end

  # Dangerous CSS that has not (yet) been approved for other readers.
  def pending_review?
    dangerous? && !approved?
  end

  # The CSS to actually inject for a given viewer. The owner sees their own raw
  # CSS (they accept their own risk); everyone else gets the raw CSS only once a
  # mod has approved this exact version, otherwise the stripped safe version.
  def css_for(viewer)
    trusted = (viewer && viewer.id == user_id) || approved?
    (trusted ? css : sanitized_css).to_s
  end

  def approve!(mod)
    update!(approved_at: Time.zone.now, approved_by: mod, approved_digest: css_digest)
  end

  def reject!
    update!(approved_at: nil, approved_by: nil, approved_digest: nil, public: false)
  end

  private

  def recompute_derived
    sanitizer = Glowfic::CssSanitizer.new(css)
    self.sanitized_css = sanitizer.sanitized
    self.dangerous = sanitizer.dangerous?
    # Editing the CSS lapses any prior approval.
    return if approved_at.nil? || approved_digest == css_digest

    self.approved_at = nil
    self.approved_by = nil
    self.approved_digest = nil
  end
end
