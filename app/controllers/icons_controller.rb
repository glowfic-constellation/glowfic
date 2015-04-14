class IconsController < ApplicationController
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
end
