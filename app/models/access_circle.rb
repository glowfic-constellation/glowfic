# frozen_string_literal: true
class AccessCircle < Tag
  validates :name, uniqueness: { scope: [:type, :user] }

  scope :visible, -> { where(owned: false) }

  def visible_to?(user)
    return false if user.nil?
    return true unless owned?
    return true if user.admin?
    user.id == user_id
  end
end
