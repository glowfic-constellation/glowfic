# frozen_string_literal: true
class AccessCircle < Tag
  has_many :user_tags, class_name: 'Tag::UserTag', foreign_key: :tag_id, dependent: :destroy, inverse_of: :tag
  has_many :users, through: :user_tags, dependent: :destroy

  validates :name, uniqueness: { scope: [:type, :user] }

  scope :visible, -> { where(owned: false) }

  def visible_to?(user)
    return false unless logged_in?
    return true unless owned?
    return true if user.admin?
    user.id == user_id
  end
end
