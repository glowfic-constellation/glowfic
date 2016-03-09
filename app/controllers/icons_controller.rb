class IconsController < ApplicationController
  before_filter :login_required, except: :show
  before_filter :find_icon, except: :create
  before_filter :require_own_icon, only: [:edit, :update, :destroy, :avatar]

  def create
    # ignore the name. this removes icons from galleries or deletes them outright, in batches.
    icon_ids = (params[:marked_ids] || []).map(&:to_i).reject(&:zero?)
    if icon_ids.empty? or (icons = Icon.where(id: icon_ids)).empty?
      flash[:error] = "No icons selected."
      redirect_to galleries_path and return
    end

    if params[:commit] == '- Remove selected icons from gallery'
      gallery = Gallery.find_by_id(params[:gallery_id])
      unless gallery
        flash[:error] = "Gallery could not be found."
        redirect_to galleries_path and return
      end
      if gallery.user_id != current_user.id
        flash[:error] = "That is not your gallery."
        redirect_to galleries_path and return
      end

      icons.each do |icon|  
        next unless icon.user_id == current_user.id  
        gallery.icons.delete(icon)
      end
      flash[:success] = "Icons removed from gallery."
      redirect_to gallery_path(gallery) and return
    end

    icons.each do |icon|
      next unless icon.user_id == current_user.id
      icon.destroy
    end
    flash[:success] = "Icons deleted."
      redirect_to galleries_path and return
  end

  def show
  end

  def edit
  end

  def update
    if @icon.update_attributes(params[:icon])
      flash[:success] = "Icon updated."
      redirect_to icon_path(@icon)
    else
      flash.now[:error] = "Something went wrong."
      render :action => :edit
    end
  end

  def destroy
    @icon.destroy
    flash[:success] = "Icon deleted successfully."
    redirect_to galleries_path
  end

  def avatar
    if current_user.update_attributes(avatar: @icon)
      flash[:success] = "Avatar has been set!"
    else
      flash[:error] = "Something went wrong."
    end
    redirect_to icon_path(@icon)
  end

  private

  def find_icon
    unless @icon = Icon.find_by_id(params[:id])
      flash[:error] = "Icon could not be found."
      redirect_to galleries_path
    end
  end

  def require_own_icon
    if @icon.user_id != current_user.id
      flash[:error] = "That is not your icon."
      redirect_to galleries_path
    end
  end
end
