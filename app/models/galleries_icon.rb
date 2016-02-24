class GalleriesIcon < ActiveRecord::Base
  belongs_to :icon
  belongs_to :gallery

  after_create :check_has_gallery
  after_destroy :check_gallery_count

  private

  def check_has_gallery
    return if icon.has_gallery?
    icon.update_attributes(has_gallery: true)
  end

  def check_gallery_count
    return if icon.galleries.present?
    icon.update_attributes(has_gallery: false)
  end
end
