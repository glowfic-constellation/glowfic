class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    
    if params[:secret] != "ALLHAILTHECOIN"
      flash[:error] = "This is in beta. Please come back later."
      render :action => "new" and return
    end

    if @user.save
      flash[:success] = "User created! You have been logged in."
      session[:user_id] = @user.id
      @current_user = @user
      redirect_to root_url
    else
      flash[:error] = "There was a problem completing your sign up."
      render :action => "new"
    end
  end
end