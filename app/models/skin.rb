# frozen_string_literal: true
class Skin < ApplicationRecord
  belongs_to :user, inverse_of: :skins, optional: false

  validates :name, presence: true, length: { maximum: 255 }
  validates :css, length: { maximum: Glowfic::CssSanitizer::MAX_LENGTH }

  before_save :sanitize_css

  scope :ordered, -> { order(name: :asc, id: :asc) }
  scope :listed, -> { where(public: true) }

  # The raw `css` is kept for editing; `sanitized_css` is what actually gets
  # injected into pages, recomputed whenever the skin is saved.
  def sanitize_css
    self.sanitized_css = Glowfic::CssSanitizer.call(css)
  end

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
end
