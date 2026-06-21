# frozen_string_literal: true
class SkinsController < ApplicationController
  before_action :login_required, except: [:index, :show, :gallery]
  before_action :find_model, only: [:show, :edit, :update, :destroy, :use, :fork]
  before_action :require_visible, only: [:show, :use, :fork]
  before_action :require_edit_permission, only: [:edit, :update, :destroy]

  def index
    @user = params[:user_id] ? User.find_by(id: params[:user_id]) : current_user
    return login_required unless @user

    own = @user == current_user
    @page_title = own ? 'Your Skins' : "#{@user.username}'s Skins"
    skins = @user.skins.ordered
    skins = skins.listed unless own
    @skins = skins.paginate(page: page, per_page: 25)
  end

  def gallery
    @page_title = 'Skin Gallery'
    @skins = Skin.listed.ordered.paginate(page: page, per_page: 25)
  end

  def new
    @page_title = 'New Skin'
    @skin = Skin.new
  end

  def create
    @skin = Skin.new(permitted_params)
    @skin.user = current_user

    unless @skin.save
      render_errors(@skin, action: 'created', now: true)
      @page_title = 'New Skin'
      render :new and return
    end

    flash[:success] = 'Skin created.'
    redirect_to @skin
  end

  def show
    @page_title = @skin.name
  end

  def edit
    @page_title = "Edit Skin: #{@skin.name}"
  end

  def update
    unless @skin.update(permitted_params)
      render_errors(@skin, action: 'updated', now: true)
      @page_title = "Edit Skin: #{@skin.name}"
      render :edit and return
    end

    flash[:success] = 'Skin updated.'
    redirect_to @skin
  end

  def destroy
    begin
      @skin.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@skin, action: 'delete', err: e)
    else
      flash[:success] = 'Skin deleted.'
    end
    redirect_to skins_path
  end

  def use
    current_user.update!(skin_id: @skin.id)
    flash[:success] = "Now using the “#{@skin.name}” skin."
    redirect_back_or_to(@skin)
  end

  def clear
    current_user.update!(skin_id: nil)
    flash[:success] = 'Skin turned off.'
    redirect_back_or_to(skins_path)
  end

  def fork
    new_skin = @skin.fork_for(current_user)
    if new_skin.save
      flash[:success] = 'Skin copied to your skins.'
      redirect_to edit_skin_path(new_skin)
    else
      flash[:error] = 'Skin could not be copied.'
      redirect_to @skin
    end
  end

  private

  def permitted_params
    params.fetch(:skin, {}).permit(:name, :description, :css, :public)
  end

  def find_model
    return if (@skin = Skin.find_by(id: params[:id]))
    flash[:error] = 'Skin could not be found.'
    redirect_to skins_path
  end

  def require_visible
    return if @skin.visible_to?(current_user)
    flash[:error] = 'Skin could not be found.'
    redirect_to skins_path
  end

  def require_edit_permission
    return if @skin.editable_by?(current_user)
    flash[:error] = 'You do not have permission to edit that skin.'
    redirect_to skin_path(@skin)
  end
end
