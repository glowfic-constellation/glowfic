class Taggable::Tag < ActsAsTaggableOn::Tag
  has_many :child_taggings, class_name: 'ActsAsTaggableOn::Tagging', dependent: :destroy

  has_many :owners, through: :child_taggings, source: :taggable, source_type: 'User', dependent: :destroy
  has_many :posts, through: :child_taggings, source: :taggable, source_type: "Post", dependent: :destroy
  has_many :characters, through: :child_taggings, source: :taggable, source_type: "Character", dependent: :destroy

  TYPES = %w(ContentWarning Label Setting GalleryGroup)

  validates :name, uniqueness: { scope: :type }

  def self.for_context(context)
    joins(:child_taggings)
      .where(["#{ActsAsTaggableOn.taggings_table}.context = ?", context])
      .select("DISTINCT #{ActsAsTaggableOn.tags_table}.*")
  end

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
