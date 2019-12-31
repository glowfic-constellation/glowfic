class GalleryTag < ApplicationRecord
  belongs_to :gallery, inverse_of: :gallery_tags, optional: false
  belongs_to :tag, inverse_of: :gallery_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :gallery_group, foreign_key: :tag_id, inverse_of: :gallery_tags, optional: false # This is currently required but may not continue to be
end
