class GalleriesController < ApplicationController
  before_filter :login_required, except: :show
  before_filter :find_gallery, only: [:add, :icon, :destroy, :remove, :edit, :update]

  def index
    use_javascript('galleries/index')
    @page_title = "Galleries"
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
    use_javascript('galleries/add')
    icons = (current_user.icons - @gallery.icons).sort { |i| i.id }
    @unassigned = icons.select { |i| i.galleries.empty? }
    @assigned = icons - @unassigned
  end

  def show
    @gallery = Gallery.find_by_id(params[:id])
    respond_to do |format|
      format.json { render json: @gallery.icons }
      format.html { render show: @gallery }
    end
  end

  def edit
  end

  def update
    if @gallery.update_attributes(params[:gallery])
      flash[:success] = "Gallery saved."
      redirect_to galleries_path
    else
      flash.now[:error] = "Gallery could not be saved."
      render action: :edit
    end
  end

  def icon
    icon_ids = params[:image_ids].split(',').map(&:to_i).reject(&:zero?)
    icons = Icon.where(id: icon_ids)
    icons.each do |icon|
      next unless icon.user_id == current_user.id
      @gallery.icons << icon
    end
    flash[:success] = "Icons added to gallery successfully."
    redirect_to galleries_path
  end

  def destroy
    @gallery.destroy
    flash[:success] = "Gallery deleted successfully."
    redirect_to galleries_path
  end

  def remove
    icon = Icon.find(params[:icon_id])
    @gallery.icons.delete(icon)
    render json: {}
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
end
