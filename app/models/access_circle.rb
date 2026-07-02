# frozen_string_literal: true
class AccessCircle < Tag
  has_many :user_tags, foreign_key: :tag_id, dependent: :destroy, inverse_of: :tag
  has_many :users, through: :user_tags, inverse_of: :access_circles, dependent: :destroy

  validates :name, uniqueness: { scope: [:type, :user] }

  scope :visible, -> { where(owned: false) }

  def visible_to?(user)
    return false if user.nil?
    return true unless owned?
    return true if user.admin?
    user.id == user_id
  end
end
