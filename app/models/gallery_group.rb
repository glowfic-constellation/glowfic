class GalleryGroup < Tag
  has_many :galleries, through: :child_taggings, source: :taggable, source_type: "Gallery", dependent: :destroy
end
