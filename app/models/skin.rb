# frozen_string_literal: true
class Skin < ApplicationRecord
  audited

  belongs_to :user, inverse_of: :skins, optional: false
  belongs_to :approved_by, class_name: 'User', inverse_of: false, optional: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :css, length: { maximum: Glowfic::CssSanitizer::MAX_LENGTH }

  before_save :recompute_derived

  # Descendant prefix every skin selector is scoped under (see #stylesheet_for)
  # so an injected skin out-ranks the application's own theming — many of those
  # rules use :nth-child / #id selectors a bare ".x" skin selector can't beat —
  # without relying on !important, which the sanitizer strips for non-owners.
  SCOPE = ':root:root'

  # Appended after every served skin. Skins have `!important` stripped by the
  # sanitizer, so these always win: critical chrome (content warnings, flashes,
  # the ToS gate) stays visible and un-overlaid no matter what a skin tries.
  #
  # The property list is the set of ways CSS can hide, shrink-to-nothing, move
  # off-screen, or de-interact an element, each pinned to its "no-op" value:
  #   * hide: display, visibility, opacity
  #   * collapse: height, max-height, overflow
  #   * move/transform: position, transform AND the independent transform
  #     properties (scale/rotate/translate, which bypass `transform: none`)
  #   * clip away: clip, clip-path
  #   * obscure: filter (e.g. opacity()/blur())
  #   * disable: pointer-events
  SAFETY_OVERRIDES = <<~CSS
    #{SCOPE} .flash, #{SCOPE} .flash.error, #{SCOPE} .flash-margin, #{SCOPE} #tos {
      display: block !important;
      visibility: visible !important;
      opacity: 1 !important;
      position: static !important;
      height: auto !important;
      max-height: none !important;
      overflow: visible !important;
      transform: none !important;
      scale: none !important;
      rotate: none !important;
      translate: none !important;
      filter: none !important;
      clip: auto !important;
      clip-path: none !important;
      pointer-events: auto !important;
    }
  CSS

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

  # Whether a viewer gets the raw CSS: the owner sees their own (they accept
  # their own risk); everyone else only once a mod has approved this exact
  # version. Untrusted viewers get the sanitized version instead.
  def trusted_for?(viewer)
    (viewer && viewer.id == user_id) || approved?
  end

  # The CSS to actually inject for a given viewer.
  def css_for(viewer)
    (trusted_for?(viewer) ? css : sanitized_css).to_s
  end

  # The full stylesheet served at /skins/:id/css for a viewer: the viewer's CSS
  # tier, scoped under SCOPE, with the safety overrides appended. Because this is
  # served as a standalone text/css file (not embedded in an HTML <style>), there
  # is no markup context to break out of, so no escaping is needed.
  def stylesheet_for(viewer)
    scoped = Glowfic::CssSanitizer.scope(css_for(viewer), SCOPE)
    return '' if scoped.blank?

    "#{scoped}\n#{SAFETY_OVERRIDES}"
  end

  # Whether the skin's stylesheet may be fetched by this viewer. Mirrors the
  # existing exposure: a skin you can see (own/public), or one recommended on a
  # post (the recommended skin is served to that post's readers regardless of
  # the skin's own privacy).
  def viewable_as_stylesheet_by?(viewer)
    visible_to?(viewer) || recommended_on_a_post?
  end

  def recommended_on_a_post?
    Post.where(skin_id: id).exists?
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
