class SessionsController < ApplicationController
  def index
  end

  def create
    user = User.find_by_username(params[:username])

    if !user
      flash[:error] = "That username does not exist."
    elsif user.authenticate(params[:password])
      flash[:success] = "You are now logged in as #{user.username}. Welcome back!"
      session[:user_id] = user.id
      @current_user = user
    else
      flash[:error] = "You have entered an incorrect password."
    end
    redirect_to root_url
  end

  def destroy
    reset_session
    @current_user = nil
    redirect_to root_url
  end
end
