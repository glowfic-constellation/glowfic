class SessionsController < ApplicationController
  before_filter :logout_required, only: [:new, :create]
  before_filter :login_required, only: [:destroy]

  def index
    redirect_to boards_path and return if logged_in?
  end

  def new
    @page_title = "Sign In"
  end

  def create
    user = User.find_by_username(params[:username])

    if !user
      flash[:error] = "That username does not exist."
    elsif user.password_resets.active.unused.exists?
      flash[:error] = "The password for this account has been reset. Please check your email."
    elsif user.authenticate(params[:password])
      flash[:success] = "You are now logged in as #{user.username}. Welcome back!"
      session[:user_id] = user.id
      cookies.permanent.signed[:user_id] = user.id if params[:remember_me].present?
      @current_user = user
      redirect_to boards_path and return if session[:previous_url] == '/login'
    else
      flash[:error] = "You have entered an incorrect password."
    end
    redirect_to session[:previous_url] || root_url
  end

  def destroy
    url = session[:previous_url] || root_url
    reset_session
    cookies.delete(:user_id)
    @current_user = nil
    flash[:success] = "You have been logged out."
    redirect_to url
  end

  private

  def logout_required
    if logged_in?
      flash[:error] = "You are already logged in."
      redirect_to boards_path
    end
  end
end
