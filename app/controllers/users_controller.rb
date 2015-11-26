class UsersController < ApplicationController
  before_filter :signup_prep, :only => :new
  before_filter :login_required, :except => [:new, :create, :username]

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    
    if params[:secret] != "ALLHAILTHECOIN"
      flash.now[:error] = "This is in beta. Please come back later."
      render :action => "new" and return
    end

    if @user.save
      flash[:success] = "User created! You have been logged in."
      session[:user_id] = @user.id
      @current_user = @user
      redirect_to root_url
    else
      signup_prep
      flash.now[:error] = "There was a problem completing your sign up."
      render :action => "new"
    end
  end

  def edit
    use_javascript('users')
  end

  def update
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
      render action: :edit and return
    end
    
    if current_user.update_attributes(params[:user])
      flash[:success] = "Changes saved successfully."
      redirect_to edit_user_path(current_user)
    else
      flash.now[:error] = "There was a problem with your changes."
      render action: :edit
    end
  end

  def username
    render :json => { :error => "No username provided." } and return unless params[:username]
    render :json => { :username_free => User.find_by_username(params[:username]).nil? }
  end

  def character
    character = Character.find_by_id(params[:character_id])
    current_user.update_attributes(:active_character => character)

    render :json => {} and return unless character.try(:gallery)
    render :json => { :gallery => character.gallery.icons.order("keyword ASC").map(&:to_json), :default => character.icon.try(:to_json) }
  end

  private

  def signup_prep
    use_javascript('users')
    gon.max = User::MAX_USERNAME_LEN
    gon.min = User::MIN_USERNAME_LEN
  end
end