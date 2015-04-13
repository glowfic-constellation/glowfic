class SessionsController < ApplicationController
  def index
  end

  def create
    user = User.find_by_username(params[:username])
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      @current_user = user
      redirect_to root_url
    end
  end

  def destroy
    reset_session
    @current_user = nil
    redirect_to root_url
  end
end
