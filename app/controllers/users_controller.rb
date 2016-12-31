# frozen_string_literal: true
class UsersController < ApplicationController
  before_filter :signup_prep, :only => :new
  before_filter :login_required, :except => [:index, :show, :new, :create, :username]

  def index
    @page_title = 'Glowficcers'
  end

  def show
    unless @user = User.find_by_id(params[:id])
      flash[:error] = "User could not be found."
      redirect_to users_path and return
    end

    post_ids = Post.where(user_id: @user.id).order('tagged_at desc').pluck(:id)
    reply_ids = Reply.where(user_id: @user.id).pluck('distinct post_id')
    ids = (post_ids + reply_ids).uniq
    @posts = posts_from_relation(Post.where(id: ids).order('tagged_at desc'))
    @page_title = @user.username
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    @user.validate_password = true

    if params[:secret] != "ALLHAILTHECOIN"
      signup_prep
      flash.now[:error] = "This is in beta. Please come back later."
      render :action => :new and return
    end

    unless @user.save
      signup_prep
      flash.now[:error] = {}
      flash.now[:error][:message] = "There was a problem completing your sign up."
      flash.now[:error][:array] = @user.errors.full_messages
      render :action => :new and return
    end

    flash[:success] = "User created! You have been logged in."
    session[:user_id] = @user.id
    @current_user = @user
    redirect_to root_url
  end

  def edit
    use_javascript('users/edit')
    @page_title = 'Edit Account'
  end

  def update
    params[:user][:per_page] = -1 if params[:user].try(:[], :per_page) == 'all'
    if current_user.update_attributes(params[:user])
      flash[:success] = "Changes saved successfully."
    else
      flash[:error] = "There was a problem with your changes."
    end
    redirect_to edit_user_path(current_user)
  end

  def password
    unless current_user.authenticate(params[:old_password])
      flash.now[:error] = "Incorrect password entered."
      @page_title = 'Edit Account'
      render action: :edit and return
    end

    current_user.validate_password = true
    if current_user.update_attributes(params[:user])
      flash[:success] = "Changes saved successfully."
      redirect_to edit_user_path(current_user)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "There was a problem with your changes."
      flash.now[:error][:array] = current_user.errors.full_messages
      @page_title = 'Edit Account'
      render action: :edit
    end
  end

  def username
    render :json => { :error => "No username provided." } and return unless params[:username]
    render :json => { :username_free => User.find_by_username(params[:username]).nil? }
  end

  private

  def signup_prep
    use_javascript('users/new')
    gon.max = User::MAX_USERNAME_LEN
    gon.min = User::MIN_USERNAME_LEN
    @page_title = 'Sign Up'
  end
end
