class Taggable::Tag < ActsAsTaggableOn::Tag
  has_many :child_taggings, class_name: 'ActsAsTaggableOn::Tagging', dependent: :destroy

  has_many :owners, through: :child_taggings, source: :taggable, source_type: 'User', dependent: :destroy
  has_many :posts, through: :child_taggings, source: :taggable, source_type: "Post", dependent: :destroy
  has_many :characters, through: :child_taggings, source: :taggable, source_type: "Character", dependent: :destroy

  TYPES = %w(ContentWarning Label Setting GalleryGroup)

  validates :name, uniqueness: { scope: :type }

  # disables the AATO unscoped uniqueness validation
  def validates_name_uniqueness?
    false
  end

  def self.for_context(context)
    where(type: context.constantize)
  end

  # overrides the complicated thing AATO does because their column isn't citext
  def self.named_any(list)
    where(name: list)
  end

  def editable_by?(user)
    return false unless user
    return true if deletable_by?(user)
    return true if user.has_permission?(:edit_tags)
  end

  def deletable_by?(user)
    return false unless user
    return true if user.has_permission?(:delete_tags)
    owner_ids.include?(user.id)
  end
end
