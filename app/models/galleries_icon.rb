class GalleriesIcon < ActiveRecord::Base
  belongs_to :icon
  belongs_to :gallery
end
