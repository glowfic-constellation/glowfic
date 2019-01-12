class Icon::Replacer < Generic::Replacer
  def initialize(icon)
    @icon = icon
  end

  def setup(user:, no_icon_url:)
    all_icons = if @icon.has_gallery?
      @icon.galleries.flat_map(&:icons).uniq.compact - [@icon]
    else
      user.galleryless_icons - [@icon]
    end
    @alts = all_icons.sort_by { |i| i.keyword.downcase }

    @gallery = all_icons.to_h { |i| [i.id, { url: i.url, keyword: i.keyword }] }
    @gallery[''] = { url: no_icon_url, keyword: 'No Icon' }

    post_ids = Reply.where(icon_id: @icon.id).select(:post_id).distinct.pluck(:post_id)
    @posts = Post.where(icon_id: @icon.id).or(Post.where(id: post_ids)).distinct
  end

  def replace(params, user:)
    unless params[:icon_dropdown].blank? || (new_icon = Icon.find_by_id(params[:icon_dropdown]))
      @errors.add(:icon, "could not be found.") && return
    end

    @errors.add(:base, "You do not have permission to modify this icon.") && return if new_icon && new_icon.user_id != user.id

    wheres = { icon_id: @icon.id }
    wheres[:post_id] = params[:post_ids] if params[:post_ids].present?
    UpdateModelJob.perform_later(Reply.to_s, wheres, { icon_id: new_icon.try(:id) })
    wheres[:id] = wheres.delete(:post_id) if params[:post_ids].present?
    UpdateModelJob.perform_later(Post.to_s, wheres, { icon_id: new_icon.try(:id) })
  end
end
