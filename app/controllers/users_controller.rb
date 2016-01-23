class UsersController < ApplicationController
  before_filter :signup_prep, :only => :new
  before_filter :login_required, :except => [:index, :show, :new, :create, :username]

  def index
  end

  def show
    unless @user = User.find_by_id(params[:id])
      flash[:error] = "User could not be found."
      redirect_to users_path and return
    end
    post_ids = Post.where(user_id: @user.id).order('updated_at desc').limit(25).select(:id).map(&:id)
    reply_ids = Reply.where(user_id: @user.id).group(:post_id).limit(25).select("post_id, max(updated_at)").map(&:post_id)
    ids = (post_ids + reply_ids).uniq
    @posts = Post.where(id: ids).order('updated_at desc').limit(25).includes(:board).includes(:user)
  end

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
    render :json => CharacterPresenter.new(character)
  end

  private

  def signup_prep
    use_javascript('users')
    gon.max = User::MAX_USERNAME_LEN
    gon.min = User::MIN_USERNAME_LEN
  end
end