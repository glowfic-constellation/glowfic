# frozen_string_literal: true
class GalleriesController < UploadingController
  include Taggable

  before_action :login_required, except: [:index, :show, :search]
  before_action :find_model, only: [:destroy, :edit, :update]
  before_action :require_edit_permission, only: [:edit, :update, :destroy]
  before_action :require_create_permission, only: [:new, :create, :add, :icon]
  before_action :find_user, only: [:index]
  before_action :require_own_gallery, only: [:add, :icon]
  before_action :setup_new_icons, only: [:add, :icon]
  before_action :set_s3_url, only: [:edit, :add, :icon]
  before_action :editor_setup, only: [:new, :edit]

  def index
    @page_title = if @user.id == current_user.try(:id)
      "Your Galleries"
    else
      @user.username + "'s Galleries"
    end
    @galleries = @user.galleries.ordered_by_name
    @galleries = @galleries.paginate(per_page: 100, page: page)
    use_javascript('galleries/expander')
    gon.user_id = @user.id
  end

  def new
    @page_title = 'New Gallery'
    @gallery = Gallery.new
  end

  def create
    @gallery = Gallery.new(permitted_params)
    @gallery.user = current_user
    @gallery.gallery_groups = process_tags(GalleryGroup, obj_param: :gallery, id_param: :gallery_group_ids)

    begin
      @gallery.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@gallery, action: 'created', now: true, err: e)

      @page_title = 'New Gallery'
      editor_setup
      render :new
    else
      flash[:success] = "Gallery created."
      redirect_to @gallery
    end
  end

  def add
    return unless params[:id] == '0' && params[:type] == 'existing'
    flash[:error] = 'Cannot add existing icons to galleryless. Please remove from existing galleries instead.'
    redirect_to user_gallery_path(id: 0, user_id: current_user.id)
  end

  def show
    if params[:id].to_s == '0' # avoids casting nils to 0
      find_user
      return if performed?
      @page_title = 'Galleryless Icons'
    else
      return unless find_model
      @user = @gallery.user
      @page_title = @gallery.name + ' (Gallery)'
      @meta_og = og_data
    end
    @icons = @gallery ? @gallery.icons : @user.galleryless_icons
    @icons = @icons.paginate(per_page: 100, page: page)
    @times_used, @posts_used = Icon.times_used(@icons, current_user) if page_view == 'list'
    response.headers['X-Robots-Tag'] = 'noindex' if params[:view]
    render :show, locals: { icons: @icons }
  end

  def edit
    @page_title = 'Edit Gallery: ' + @gallery.name
    use_javascript('galleries/uploader')
    use_javascript('galleries/edit')
  end

  def update
    @gallery.assign_attributes(permitted_params)

    begin
      Gallery.transaction do
        @gallery.gallery_groups = process_tags(GalleryGroup, obj_param: :gallery, id_param: :gallery_group_ids)
        @gallery.save!
      end
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@gallery, action: 'updated', now: true, err: e)

      @page_title = 'Edit Gallery: ' + @gallery.name_was
      use_javascript('galleries/uploader')
      use_javascript('galleries/edit')
      editor_setup
      set_s3_url
      render :edit
    else
      flash[:success] = "Gallery updated."
      redirect_to edit_gallery_path(@gallery)
    end
  end

  def icon
    adder = Gallery::IconAdder.new(@gallery, user: current_user, params: params)

    if params[:image_ids].present?
      adder.assign_existing
    else
      adder.create_new
    end
    @icons = adder.icons
    if adder.errors.present?
      error = adder.errors.full_messages.first
      if adder.icon_errors.present?
        flash[:error] = {
          message: error,
          array: adder.icon_errors,
        }
      else
        flash[:error] = error
      end
      if @gallery.nil? && params[:image_ids].present?
        redirect_to user_galleries_path(current_user)
      else
        render :add
      end
    else
      flash[:success] = "Icons #{params[:image_ids].present? ? 'added to gallery' : 'saved'}."
      redirect_to @gallery || user_gallery_path(id: 0, user_id: current_user.id)
    end
  end

  def destroy
    begin
      @gallery.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@gallery, action: 'deleted', err: e)
      redirect_to @gallery
    else
      flash[:success] = "Gallery deleted."
      redirect_to user_galleries_path(current_user)
    end
  end

  def search
  end

  private

  def find_model
    return true if (@gallery = Gallery.find_by(id: params[:id]))
    flash[:error] = "Gallery could not be found."
    redirect_to(logged_in? ? user_galleries_path(current_user) : root_path)
    false
  end

  def require_edit_permission
    return if @gallery.user_id == current_user.id
    flash[:error] = "You do not have permission to modify this gallery."
    redirect_to user_galleries_path(current_user)
  end

  def require_create_permission
    return unless current_user.read_only?
    flash[:error] = "You do not have permission to create galleries."
    redirect_to continuities_path
  end

  def require_own_gallery
    return if params[:id].to_s == '0'
    return unless find_model
    require_edit_permission
  end

  def find_user
    if params[:user_id].present?
      unless (@user = User.active.full.find_by(id: params[:user_id]))
        flash[:error] = 'User could not be found.'
        redirect_to root_path
      end
    else
      return if login_required
      return if readonly_forbidden
      @user = current_user
    end
  end

  def setup_new_icons
    if params[:type] == "existing"
      use_javascript('galleries/add_existing')
    else
      use_javascript('galleries/add_new')
      use_javascript('galleries/uploader')
    end
    @icons = []
    @unassigned = current_user.galleryless_icons
    @page_title = "Add Icons"
    @page_title += ": " + @gallery.name unless @gallery.nil?
  end

  def editor_setup
    use_javascript('galleries/editor')
    gon.user_id = current_user.id
  end

  def og_data
    icon_count = @gallery.icons.count
    desc = ["#{icon_count} " + "icon".pluralize(icon_count)]
    tags = @gallery.gallery_groups_data.pluck(:name)
    tag_count = tags.count
    desc << ("Tag".pluralize(tag_count) + ": " + generate_short(tags.join(', '))) if tag_count > 0
    title = [@gallery.name]
    title.prepend(@gallery.user.username) unless @gallery.user.deleted?
    {
      url: gallery_url(@gallery),
      title: title.join(' » '),
      description: desc.join("\n"),
    }
  end

  def permitted_params
    params.fetch(:gallery, {}).permit(
      :name,
      galleries_icons_attributes: [
        :id,
        :_destroy,
        icon_attributes: [:url, :keyword, :credit, :id, :_destroy, :s3_key],
      ],
      icon_ids: [],
    )
  end

  def icon_params(paramset)
    paramset.permit(:url, :keyword, :credit, :s3_key)
  end
end
