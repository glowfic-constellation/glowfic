# frozen_string_literal: true
class AccessCircle < Tag
  has_many :user_tags, class_name: 'Tag::UserTag', foreign_key: :tag_id, dependent: :destroy, inverse_of: :tag
  has_many :users, through: :user_tags, dependent: :destroy
  has_many :user_default_access_circles, foreign_key: :tag_id, dependent: :destroy, inverse_of: :access_circle

  validates :name, uniqueness: { scope: [:type, :user] }

  scope :visible, -> { where(owned: false) }
  scope :attachable_by, ->(user) {
    return none unless user
    where(user: user).or(visible).ordered_by_name
  }

  def visible_to?(user)
    return false if user.nil?
    return true unless owned?
    return true if user.admin?
    user.id == user_id
  end

  def joinable_by?(user)
    return false unless joinable?
    return false unless visible_to?(user)
    user.id != user_id && !user_ids.include?(user.id)
  end

  def leavable_by?(user)
    return false unless user
    return false if user.id == user_id
    user_ids.include?(user.id)
  end
end
