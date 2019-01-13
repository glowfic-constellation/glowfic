class Icon::MultiRemover < Generic::Service
  attr_reader :gallery

  def perform(params, user:)
    @gallery = Gallery.find_by_id(params[:gallery_id])
    icon_ids = (params[:marked_ids] || []).map(&:to_i).reject(&:zero?)
    if icon_ids.empty? || (@icons = Icon.where(id: icon_ids)).empty?
      @errors.add(:base, "No icons selected.")
      return
    end

    if params[:gallery_delete]
      remove(user)
    else
      delete(user)
    end
  end

  def remove(user)
    @errors.add(:gallery, "could not be found.") unless @gallery
    @errors.add(:base, "You do not have permission to modify this gallery.") if @gallery && @gallery.user_id != user.id
    return if @errors.present?

    @icons.each do |icon|
      next unless icon.user_id == user.id
      @gallery.icons.destroy(icon)
    end
  end

  def delete(user)
    @icons.each do |icon|
      next unless icon.user_id == user.id
      icon.destroy!
    end
  end
end
