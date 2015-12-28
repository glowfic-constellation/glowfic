class IconsController < ApplicationController
  before_filter :login_required, :except => :show
  before_filter :find_icon, :only => [:show, :edit, :update, :destroy, :avatar]
  before_filter :require_own_icon, :only => [:edit, :update, :destroy, :avatar]

  def index
    @icons = current_user.icons
  end

  def new
    setup_new_icons
  end

  def create
    icons = params[:icons].reject { |icon| icon.values.all?(&:blank?) }
    if icons.empty?
      flash.now[:error] = "You have to enter something."
      setup_new_icons
      render :action => :new and return
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
      render :action => :new and return
    elsif icons.empty?
      @icons = []
      flash.now[:error] = "Your icons could not be saved."
      use_javascript('icons')
      render :action => :new
    elsif icons.all?(&:save)
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

  def edit
  end

  def update
    if @icon.update_attributes(params[:icon])
      flash[:success] = "Icon updated"
      redirect_to icon_path(@icon)
    else
      flash.now[:error] = "Something went wrong."
      render :action => :edit
    end
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

  def setup_new_icons
    use_javascript('icons')
    @icons = []
  end
end
