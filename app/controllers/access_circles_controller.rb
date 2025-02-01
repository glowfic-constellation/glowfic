# frozen_string_literal: true
class AccessCirclesController < ApplicationController
  before_action :login_required
  before_action :find_model, only: [:show, :edit, :update, :destroy]
  before_action :find_user, only: [:index]
  before_action :require_create_permission, only: [:new, :create]
  before_action :require_edit_permission, only: [:edit, :update]
  before_action :require_delete_permission, only: [:destroy]
  before_action :require_index_permission, only: [:index]
  before_action :editor_setup, only: [:new, :edit]

  def index
    @public = params[:user_id].nil?

    @page_title = if @public
      'Public Access Circles'
    elsif @user.id == current_user.id
      "Your Access Circles"
    else
      @user.username + "'s Access Circles"
    end

    @circles = @public ? AccessCircle.visible : AccessCircle.where(user: @user)
    @circles.ordered_by_name.paginate(page: page)
  end

  def new
    @page_title = 'New Access Circle'
    @circle = AccessCircle.new(user: current_user)
  end

  def create
    @circle = AccessCircle.new(user: current_user)
    @circle.assign_attributes(permitted_params)
    @circle.users = User.where(id: params[:access_circle].fetch(:user_ids, []))

    unless @circle.save
      @page_title = 'New Access Circle'
      flash.now[:error] = {
        message: "Your access circle could not be saved.",
        array: @circle.errors.full_messages,
      }
      editor_setup
      render :new and return
    end

    flash[:success] = "Access circle saved successfully."
    redirect_to @circle
  end

  def show
    @page_title = @circle.name
    @view = params[:view]

    case @view
      when 'posts'
        @posts = posts_from_relation(@circle.posts.ordered)
      when 'users'
        @users = @circle.users.paginate(page: page)
      else
        @view = 'info'
    end
  end

  def edit
    @page_title = 'Edit Access Circle: ' + @circle.name
  end

  def update
    @circle.assign_attributes(permitted_params)
    @users = User.where(id: params[:access_circle].fetch(:user_ids, []))

    begin
      AccessCircle.transaction do
        @circle.users = @users
        @circle.save!
      end
    rescue ActiveRecord::RecordInvalid
      @page_title = 'Edit Access Circle: ' + @circle.name
      flash.now[:error] = {
        message: "Your access circle could not be saved.",
        array: @circle.errors.full_messages,
      }
      editor_setup
      render :edit
    else
      flash[:success] = "Access circle saved successfully."
      redirect_to @circle
    end
  end

  def destroy
    begin
      @circle.destroy!
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {
        message: "Access circle could not be deleted.",
        array: @circle.errors.full_messages,
      }
      redirect_to @circle
    else
      flash[:success] = "Access circle deleted."
      redirect_to user_access_circles_path(current_user)
    end
  end

  private

  def find_model
    @circle = AccessCircle.find_by(id: params[:id])
    unless @circle&.visible_to?(current_user)
      flash[:error] = "Access circle could not be found."
      redirect_to user_access_circles_path(current_user)
    end
    @tag = @circle
  end

  def find_user
    return if params[:user_id].nil?
    return if (@user = User.active.find_by(id: params[:user_id]))
    flash[:error] = 'User could not be found.'
    redirect_to root_path
  end

  def require_create_permission
    return unless current_user.read_only?
    flash[:error] = "You do not have permission to create access circles."
    redirect_to continuities_path
  end

  def require_edit_permission
    return if @circle.editable_by?(current_user)
    flash[:error] = 'You do not have permission to modify this access circle'
    redirect_to user_access_circles_path(current_user)
  end

  def require_delete_permission
    return if @circle.deletable_by?(current_user)
    flash[:error] = 'You do not have permission to modify this access circle'
    redirect_to user_access_circles_path(current_user)
  end

  def require_index_permission
    return if params[:user_id].nil? || current_user.id == params[:user_id].to_i || current_user.has_permission?(:view_access_circles)
    flash[:error] = "You do not have permission to view this page."
    redirect_to root_path
  end

  def editor_setup
    use_javascript('access_circles/edit')
  end

  def permitted_params
    permitted = [:name, :description]
    params.fetch(:access_circle, {}).permit(permitted)
  end
end
