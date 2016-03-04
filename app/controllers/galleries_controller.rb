class GalleriesController < ApplicationController
  before_filter :login_required, except: :show
  before_filter :find_gallery, only: [:destroy, :remove, :edit, :update]

  def index
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
      redirect_to galleries_path
    else
      flash.now[:error] = "Your gallery could not be saved."
      @page_title = "New Gallery"
      render :action => :new
    end
  end

  def add
    find_gallery if params[:id] != '0'
    use_javascript('galleries/add')
    setup_new_icons
    icons = (current_user.icons - (@gallery.try(:icons) || [])).sort { |i| i.id }
    @unassigned = icons.reject(&:has_gallery?)
    @assigned = icons.select(&:has_gallery?)
    @page_title = "Add Icons"
  end

  def show
    respond_to do |format|
      format.json do
        if params[:id].to_i.zero?
          render json: {icons: current_user.galleryless_icons}
        else
          @gallery = Gallery.find_by_id(params[:id])
          render json: {name: @gallery.name, icons: @gallery.icons} 
        end
      end
      format.html do
        @gallery = Gallery.find_by_id(params[:id])
        @page_title = @gallery.name + " (Gallery)"
        use_javascript('galleries/index')
        render show: @gallery
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
      flash.now[:error] = "Gallery could not be saved."
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
      redirect_to galleries_path and return
    end

    icons = (params[:icons] || []).reject { |icon| icon.values.all?(&:blank?) }
    if icons.empty?
      flash.now[:error] = "You have to enter something."
      setup_new_icons
      render :action => :add and return
    end

    icons = []
    failed = false
    @icons = params[:icons].reject { |icon| icon.values.all?(&:blank?) }
    @icons.each_with_index do |icon, index|
      icon = Icon.new(icon)
      icon.user = current_user
      unless icon.valid?
        flash.now[:error] ||= {}
        flash.now[:error][:array] ||= []
        flash.now[:error][:array] += icon.errors.full_messages.map{|m| "Icon "+(index+1).to_s+": "+m.downcase}
        failed = true and next
      end
      icons << icon
    end

    if failed
      use_javascript('icons')
      flash.now[:error][:message] = "Your icons could not be saved."
      render :action => :add and return
    elsif icons.empty?
      @icons = []
      flash.now[:error] = "Your icons could not be saved."
      use_javascript('icons')
      render :action => :add
    elsif icons.all?(&:save)
      if @gallery
        icons.each do |icon| @gallery.icons << icon end
      end
      flash[:success] = "Icons saved successfully."
      redirect_to galleries_path
    else
      flash.now[:error] = "Your icons could not be saved."
      use_javascript('icons')
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
    use_javascript('icons')
    @icons = []
  end
end
