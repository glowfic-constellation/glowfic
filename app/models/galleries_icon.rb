class GalleriesIcon < ActiveRecord::Base
  belongs_to :icon
  belongs_to :gallery
  accepts_nested_attributes_for :icon, allow_destroy: true
end
