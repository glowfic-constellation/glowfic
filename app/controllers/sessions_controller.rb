class SessionsController < ApplicationController
  def index
    redirect_to boards_path and return if logged_in?
  end

  def create
    user = User.find_by_username(params[:username])

    if !user
      flash[:error] = "That username does not exist."
    elsif user.authenticate(params[:password])
      flash[:success] = "You are now logged in as #{user.username}. Welcome back!"
      session[:user_id] = user.id
      cookies.permanent.signed[:user_id] = user.id if params[:remember_me].present?
      @current_user = user
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
end
