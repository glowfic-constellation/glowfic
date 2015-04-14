class IconsController < ApplicationController
  before_filter :find_icon, :only => [:show, :destroy]

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
      flash[:error] = "Your icon could not be saved."
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
