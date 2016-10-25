class GalleriesController < ApplicationController
  before_filter :login_required, except: [:index, :show]
  before_filter :find_gallery, only: [:destroy, :edit, :update]
  before_filter :set_s3_url, only: [:add, :icon]
  before_filter :setup_new_icons, only: [:add, :icon]

  def index
    (return if login_required) unless params[:user_id].present?
    use_javascript('galleries/index')
    @page_title = "Your Galleries"
    @user = current_user
    if params[:user_id].present?
      @user = User.find_by_id(params[:user_id]) || current_user
      @page_title = @user.username + "'s Galleries"
    end
  end

  def new
    @gallery = Gallery.new
    @page_title = "New Gallery"
  end

  def create
    @gallery = Gallery.new(params[:gallery])
    @gallery.user = current_user
    if @gallery.save
      flash[:success] = "Gallery saved successfully."
      redirect_to gallery_path(@gallery)
    else
      flash.now[:error] = "Your gallery could not be saved."
      @page_title = "New Gallery"
      render :action => :new
    end
  end

  def add
  end

  def show
    respond_to do |format|
      format.json do
        if params[:id].to_s == '0' # avoids casting nils to 0
          user = params[:user_id].present? ? User.find_by_id(params[:user_id]) : current_user
          render json: {name: 'Galleryless', icons: user.try(:galleryless_icons) || []}
        else
          @gallery = Gallery.find_by_id(params[:id])
          render json: {name: @gallery.name, icons: @gallery.icons.sort_by{|i| i.keyword.downcase }}
        end
      end
      format.html do
        if params[:id].to_s == '0' # avoids casting nils to 0
          if params[:user_id].present?
            @user = User.find_by_id(params[:user_id])
          else
            return if login_required
            @user = current_user
          end
          @page_title = 'Galleryless Icons'
          use_javascript('galleries/index')
          render :show and return
        end

        @gallery = Gallery.find_by_id(params[:id])
        @user = @gallery.user
        @page_title = @gallery.name + " (Gallery)"
        use_javascript('galleries/index')
      end
    end
  end

  def edit
  end

  def update
    if @gallery.update_attributes(params[:gallery])
      flash[:success] = "Gallery saved."
      redirect_to gallery_path(@gallery)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "Gallery could not be saved."
      flash.now[:error][:array] = @gallery.errors.full_messages
      render action: :edit
    end
  end

  def icon
    find_gallery if params[:id] != '0'

    if params[:image_ids].present?
      unless @gallery # gallery required for adding icons from other galleries
        flash[:error] = "Gallery could not be found."
        redirect_to galleries_path and return
      end

      icon_ids = params[:image_ids].split(',').map(&:to_i).reject(&:zero?)  
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

    icons = []
    failed = false
    @icons = params[:icons].reject { |icon| icon.values.all?(&:blank?) }
    @icons.each_with_index do |icon, index|
      icon = Icon.new(icon.except('file'))
      icon.user = current_user
      unless icon.valid?
        @icons[index]['url'] = '' if icon.errors.messages[:url] && icon.errors.messages[:url].include?('has already been taken')
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
      redirect_to gallery_path(id: 0)
    else
      flash.now[:error] = "Your icons could not be saved."
      render :action => :add
    end
  end

  def destroy
    @gallery.destroy
    flash[:success] = "Gallery deleted successfully."
    redirect_to galleries_path
  end

  private

  def find_gallery
    @gallery = Gallery.find_by_id(params[:id])

    unless @gallery
      flash[:error] = "Gallery could not be found."
      redirect_to galleries_path and return
    end

    if @gallery.user_id != current_user.id
      flash[:error] = "That is not your gallery."
      redirect_to galleries_path and return
    end
  end

  def setup_new_icons
    if params[:type] == "existing"
      use_javascript('galleries/add_existing')
    else
      use_javascript('galleries/add_new')
    end  
    @icons = []
    find_gallery if params[:id] != '0'
    @unassigned = current_user.galleryless_icons
    @page_title = "Add Icons"
  end

  def set_s3_url
    if Rails.env.development? && !S3_BUCKET.present?
      logger.error "S3_BUCKET does not exist; icon upload will FAIL."
      @s3_direct_post = Struct.new(:url, :fields).new('', nil)
      return
    end

    @s3_direct_post = S3_BUCKET.presigned_post(
      key: "users/#{current_user.id}/icons/#{SecureRandom.uuid}_${filename}",
      success_action_status: '201',
      acl: 'public-read',
      content_type_starts_with: 'image/',
      cache_control: 'public, max-age=31536000')
  end
end
