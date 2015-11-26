class IconsController < ApplicationController
  before_filter :login_required
  before_filter :find_icon, :only => [:show, :destroy, :avatar]

  def index
    @icons = current_user.icons
  end

  def new
    @icon = Icon.new
  end

  def create
    @icon = Icon.new(params[:icon])
    @icon.user = current_user
    if @icon.save
      flash[:success] = "Icon saved successfully."
      redirect_to icons_path
    else
      flash.now[:error] = "Your icon could not be saved."
      render :action => :new
    end
  end

  def show
  end

  def destroy
    @icon.destroy
    flash[:success] = "Icon deleted successfully."
    redirect_to icons_path
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
    @icon = Icon.find_by_id(params[:id])

    unless @icon
      flash[:error] = "Icon could not be found."
      redirect_to icons_path and return
    end

    if @icon.user_id != current_user.id
      flash[:error] = "That is not your icon."
      redirect_to icons_path and return
    end
  end
end
