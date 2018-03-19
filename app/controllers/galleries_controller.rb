# frozen_string_literal: true
class GalleriesController < UploadingController
  include Taggable

  before_action :login_required, except: [:index, :show]
  before_action :find_gallery, only: [:destroy, :edit, :update]
  before_action :setup_new_icons, only: [:add, :icon]
  before_action :set_s3_url, only: [:edit, :add, :icon]
  before_action :setup_editor, only: [:new, :edit]

  def index
    if params[:user_id].present?
      unless (@user = User.find_by_id(params[:user_id]) || current_user)
        flash[:error] = 'User could not be found.'
        redirect_to root_path and return
      end
    else
      return if login_required
      @user = current_user
    end

    @page_title = if @user.id == current_user.try(:id)
      "Your Galleries"
    else
      @user.username + "'s Galleries"
    end
    use_javascript('galleries/expander')
    gon.user_id = @user.id
  end

  def new
    @page_title = 'New Gallery'
    @gallery = Gallery.new
  end

  def create
    @gallery = Gallery.new(gallery_params)
    @gallery.user = current_user
    @gallery.gallery_groups = process_tags(GalleryGroup, :gallery, :gallery_group_ids)

    unless @gallery.save
      flash.now[:error] = "Your gallery could not be saved."
      @page_title = 'New Gallery'
      setup_editor
      render :action => :new and return
    end

    flash[:success] = "Gallery saved successfully."
    redirect_to gallery_path(@gallery)
  end

  def add
    if params[:id] == '0' && params[:type] == 'existing'
      flash[:error] = 'Cannot add existing icons to galleryless. Please remove from existing galleries instead.'
      redirect_to user_gallery_path(id: 0, user_id: current_user.id)
    end
  end

  def show
    if params[:id].to_s == '0' # avoids casting nils to 0
      if params[:user_id].present?
        unless (@user = User.find_by_id(params[:user_id]))
          flash[:error] = 'User could not be found.'
          redirect_to root_path and return
        end
      else
        return if login_required
        @user = current_user
      end
      @page_title = 'Galleryless Icons'
      render :show and return
    end

    @gallery = Gallery.find_by_id(params[:id])
    unless @gallery
      flash[:error] = "Gallery could not be found."
      if logged_in?
        redirect_to user_galleries_path(current_user) and return
      else
        redirect_to root_path and return
      end
    end

    @user = @gallery.user
    @page_title = @gallery.name + ' (Gallery)'
  end

  def edit
    @page_title = 'Edit Gallery: ' + @gallery.name
    use_javascript('galleries/uploader')
    use_javascript('galleries/edit')
  end

  def update
    @gallery.assign_attributes(gallery_params)

    begin
      Gallery.transaction do
        @gallery.gallery_groups = process_tags(GalleryGroup, :gallery, :gallery_group_ids)
        @gallery.save!
      end
      flash[:success] = "Gallery saved."
      redirect_to edit_gallery_path(@gallery)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {}
      flash.now[:error][:message] = "Gallery could not be saved."
      flash.now[:error][:array] = @gallery.errors.full_messages
      @page_title = 'Edit Gallery: ' + @gallery.name_was
      use_javascript('galleries/uploader')
      use_javascript('galleries/edit')
      setup_editor
      set_s3_url
      render action: :edit
    end
  end

  def icon
    if params[:image_ids].present?
      unless @gallery # gallery required for adding icons from other galleries
        flash[:error] = "Gallery could not be found."
        redirect_to user_galleries_path(current_user) and return
      end

      icon_ids = params[:image_ids].split(',').map(&:to_i).reject(&:zero?)
      icon_ids -= @gallery.icons.pluck(:id)
      icons = Icon.where(id: icon_ids)
      icons.each do |icon|
        next unless icon.user_id == current_user.id
        @gallery.icons << icon
      end
      flash[:success] = "Icons added to gallery successfully."
      redirect_to gallery_path(@gallery) and return
    end

    icons = (params[:icons] || []).reject { |icon| icon.values.all?(&:blank?) }
    if icons.empty?
      flash.now[:error] = "You have to enter something."
      render :action => :add and return
    end

    failed = false
    @icons = icons
    icons = []
    @icons.each_with_index do |icon, index|
      icon = Icon.new(icon_params(icon.except('filename', 'file')))
      icon.user = current_user
      unless icon.valid?
        @icons[index]['url'] = '' if icon.errors.messages[:url]&.include?('has already been taken')
        flash.now[:error] ||= {}
        flash.now[:error][:array] ||= []
        flash.now[:error][:array] += icon.errors.full_messages.map{|m| "Icon "+(index+1).to_s+": "+m.downcase}
        failed = true and next
      end
      icons << icon
    end

    if failed
      flash.now[:error][:message] = "Your icons could not be saved."
      render :action => :add and return
    elsif icons.empty?
      @icons = []
      flash.now[:error] = "Your icons could not be saved."
      render :action => :add
    elsif icons.all?(&:save)
      flash[:success] = "Icons saved successfully."
      if @gallery
        icons.each do |icon| @gallery.icons << icon end
        redirect_to gallery_path(@gallery) and return
      end
      redirect_to user_gallery_path(id: 0, user_id: current_user.id)
    else
      flash.now[:error] = "Your icons could not be saved."
      render :action => :add
    end
  end

  def destroy
    @gallery.destroy
    flash[:success] = "Gallery deleted successfully."
    redirect_to user_galleries_path(current_user)
  end

  private

  def find_gallery
    @gallery = Gallery.find_by_id(params[:id])

    unless @gallery
      flash[:error] = "Gallery could not be found."
      if logged_in?
        redirect_to user_galleries_path(current_user) and return
      else
        redirect_to root_path and return
      end
    end

    unless @gallery.user_id == current_user.id
      flash[:error] = "That is not your gallery."
      if logged_in?
        redirect_to user_galleries_path(current_user) and return
      else
        redirect_to root_path and return
      end
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
    find_gallery unless params[:id] == '0'
    @unassigned = current_user.galleryless_icons
    @page_title = "Add Icons"
    @page_title += ": " + @gallery.name unless @gallery.nil?
  end

  def setup_editor
    use_javascript('galleries/editor')
    gon.user_id = current_user.id
  end

  def gallery_params
    params.fetch(:gallery, {}).permit(
      :name,
      galleries_icons_attributes: [
        :id,
        :_destroy,
        icon_attributes: [:url, :keyword, :credit, :id, :_destroy, :s3_key]
      ],
      icon_ids: [],
      ungrouped_gallery_ids: [],
    )
  end

  def icon_params(paramset)
    paramset.permit(:url, :keyword, :credit, :s3_key)
  end
end
