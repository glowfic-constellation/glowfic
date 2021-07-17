class AccessCircle < Tag
  has_many :user_tags, class_name: 'Tag::UserTag', foreign_key: :tag_id, dependent: :destroy, inverse_of: :tag
  has_many :users, through: :user_tags, dependent: :destroy

  scope :visible, -> { where(owned: false) }

  def visible_to?(user)
    return true unless owned?
    return true if user.admin?
    user.id == user_id
  end
end
