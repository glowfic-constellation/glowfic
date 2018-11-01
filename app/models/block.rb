class Block < ApplicationRecord
  belongs_to :blocking_user, class_name: 'User', optional: false, inverse_of: :blocks
  belongs_to :blocked_user, class_name: 'User', optional: false

  validates :blocking_user_id, uniqueness: { scope: :blocked_user_id }
  validates :hide_them, :hide_me, inclusion: { in: 0..2 }
  validate :not_blocking_self
  validate :option_chosen

  audited on: [:update, :destroy]

  scope :ordered, -> { includes(:blocked_user).sort_by { |block| [block.blocked_user.username.downcase] } }

  NONE = 0
  POSTS = 1
  ALL = 2

  def editable_by?(user)
    return false unless user
    self.blocking_user_id == user.id
  end

  def hide_my_posts?
    self.hide_me != NONE
  end

  def hide_my_content?
    self.hide_me == ALL
  end

  def hide_their_posts?
    self.hide_them != NONE
  end

  def hide_their_content?
    self.hide_them == ALL
  end

  private

  def not_blocking_self
    return unless blocking_user == blocked_user
    errors.add(:user, "cannot block themself")
  end

  def option_chosen
    return if hide_my_posts? || hide_their_posts? || block_interactions?
    errors.add(:block, "must choose at least one action to prevent")
  end
end
