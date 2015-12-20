class IconsController < ApplicationController
  before_filter :login_required
  before_filter :find_icon, :only => [:show, :destroy, :avatar]
  before_filter :require_own_icon, :only => [:destroy, :avatar]

  def index
    @icons = current_user.icons
  end

  def new
    use_javascript('icons')
  end

  def create
    icons = []
    params[:icons].each do |icon|
      next if icon.values.all?(&:blank?)
      icon = Icon.new(icon)
      icon.user = current_user
      unless icon.valid?
        flash.now[:error] = "Your icons could not be saved."
        use_javascript('icons')
        render :action => :new and return
      end
      icons << icon
    end

    if icons.all?(&:save)
      flash[:success] = "Icons saved successfully."
      redirect_to icons_path
    else
      flash.now[:error] = "Your icons could not be saved."
      use_javascript('icons')
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
  end

  def require_own_icon
    if @icon.user_id != current_user.id
      flash[:error] = "That is not your icon."
      redirect_to icons_path and return
    end
  end
end
