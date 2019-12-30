class Taggable::Setting < Taggable::Tag
  acts_as_ordered_taggable_on :settings

  has_many :parents, through: :taggings, source: :tag, dependent: :destroy
  has_many :children, through: :child_taggings, source: :taggable, source_type: "Taggable::Setting", dependent: :destroy
end
