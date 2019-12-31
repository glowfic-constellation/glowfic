class Setting < Tag
  acts_as_ordered_taggable_on :settings

  has_many :parents, through: :taggings, source: :tag, dependent: :destroy
  has_many :children, through: :child_taggings, source: :taggable, source_type: "Setting", dependent: :destroy

  def has_items?
    return true if super
    children.count > 0
  end
end
