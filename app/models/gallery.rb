class Gallery < ActiveRecord::Base
  belongs_to :user
  belongs_to :cover_icon, :class_name => Icon
  has_and_belongs_to_many :icons, after_add: :set_has_gallery, after_remove: :unset_has_gallery
  has_and_belongs_to_many :characters

  validates_presence_of :user, :name

  def default_icon
    cover_icon || icons.first
  end

  private

  def set_has_gallery(icon)
    icon.update_attributes(has_gallery: true)
  end

  def unset_has_gallery(icon)
    return if icon.galleries.present?
    icon.update_attributes(has_gallery: false)
  end
end
