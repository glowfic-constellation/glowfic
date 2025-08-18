class Icon::Replacer < Generic::Replacer
  def initialize(icon)
    @icon = icon
    @icons = []
    super()
  end

  def replace(params, user:)
    new_icon = check_target(params[:icon_dropdown], user: user)
    return if @errors.present?

    wheres = { icon_id: @icon.id }
    wheres[:post_id] = params[:post_ids] if params[:post_ids].present?
    updates = { icon_id: new_icon.try(:id) }
    replace_jobs(wheres: wheres, updates: updates, post_ids: params[:post_ids])
  end

  private

  def find_alts
    @icons = if @icon.has_gallery?
      @icon.galleries.flat_map(&:icons).uniq.compact
    else
      @icon.user.galleryless_icons
    end
    @icons -= [@icon]
    @alts = @icons.sort_by { |i| i.keyword.downcase }
  end

  def find_posts
    super({ icon_id: @icon.id })
  end

  def construct_gallery(no_icon_url)
    gallery = @icons.to_h { |i| [i.id, { url: i.url, keyword: i.keyword }] }
    gallery[''] = { url: no_icon_url, keyword: 'No Icon' }
    gallery
  end

  def check_target(id, user:)
    super(Icon, id: id, user: user)
  end
end
