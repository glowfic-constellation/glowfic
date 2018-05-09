# frozen_string_literal: true
class UsersController < ApplicationController
  include DateSelectable

  before_action :signup_prep, :only => :new
  before_action :login_required, :except => [:index, :show, :new, :create, :search]
  before_action :logout_required, only: [:new, :create]
  before_action :require_own_user, only: [:edit, :update, :password]

  def index
    @page_title = 'Users'
    @users = User.where(deleted: false).ordered.paginate(page: page, per_page: 25)
  end

  def show
    unless (@user = User.find_by_id(params[:id]) && !@user.deleted?)
      flash[:error] = "User could not be found."
      redirect_to users_path and return
    end

    ids = PostAuthor.where(user_id: @user.id, joined: true).pluck(:post_id)
    @posts = posts_from_relation(Post.where(id: ids).ordered)
    @page_title = @user.username
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.validate_password = true

    unless params[:tos].present?
      signup_prep
      flash.now[:error] = "You must accept the Terms and Conditions to use the Constellation."
      render :new and return
    end
    @user.tos_version = User::CURRENT_TOS_VERSION

    if params[:secret] != "ALLHAILTHECOIN"
      signup_prep
      flash.now[:error] = "This is in beta. Please ask someone in the community for the (not very) secret beta code."
      render :new and return
    end

    unless @user.save
      signup_prep
      flash.now[:error] = {}
      flash.now[:error][:message] = "There was a problem completing your sign up."
      flash.now[:error][:array] = @user.errors.full_messages
      render :new and return
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
    store_tos and return if params[:tos_check]

    params[:user][:per_page] = -1 if params[:user].try(:[], :per_page) == 'all'
    unless current_user.update(user_params)
      flash.now[:error] = {}
      flash.now[:error][:message] = "There was a problem updating your account."
      flash.now[:error][:array] = current_user.errors.full_messages
      use_javascript('users/edit')
      @page_title = 'Edit Account'
      render :edit and return
    end

    flash[:success] = "Changes saved successfully."
    redirect_to edit_user_path(current_user)
  end

  def password
    unless current_user.authenticate(params[:old_password])
      flash.now[:error] = "Incorrect password entered."
      @page_title = 'Edit Account'
      render :edit and return
    end

    current_user.validate_password = true
    if current_user.update(user_params)
      flash[:success] = "Changes saved successfully."
      redirect_to edit_user_path(current_user)
    else
      flash.now[:error] = {}
      flash.now[:error][:message] = "There was a problem with your changes."
      flash.now[:error][:array] = current_user.errors.full_messages
      @page_title = 'Edit Account'
      render :edit
    end
  end

  def search
    @page_title = 'Search Users'
    return unless params[:commit].present?
    username = '%' + params[:username].to_s + '%'
    @search_results = User.where(deleted: false).where("username LIKE ?", username).ordered.paginate(per_page: 25, page: page)
  end

  def output
    flash.now[:error] = 'Please note that this page does not include edit history.'
    use_javascript('users/output')

    @day = calculate_day
    daystart = ActiveRecord::Base.connection.quote(@day.beginning_of_day)
    dayend = ActiveRecord::Base.connection.quote(@day.end_of_day)
    @posts = Post.where(user: current_user).where('created_at between ? AND ?', daystart, dayend).pluck(:content)
    @replies = Reply.where(user: current_user).where('created_at between ? AND ?', daystart, dayend).pluck(:content)

    @total = @posts + @replies
    if @total.empty?
      @total = 0
    else
      @total[0] = @total[0].split.size
      @total = @total.inject{|r, e| r + e.split.size}.to_i
    end
  end

  private

  def require_own_user
    unless params[:id] == current_user.id.to_s
      flash[:error] = "You do not have permission to edit that user."
      redirect_to(boards_path)
    end
  end

  def signup_prep
    use_javascript('users/new')
    gon.max = User::MAX_USERNAME_LEN
    gon.min = User::MIN_USERNAME_LEN
    @page_title = 'Sign Up'
  end

  def user_params
    params.fetch(:user, {}).permit(
      :username,
      :email,
      :password,
      :password_confirmation,
      :email_notifications,
      :per_page,
      :timezone,
      :icon_picker_grouping,
      :default_view,
      :default_character_split,
      :default_editor,
      :moiety,
      :moiety_name,
      :layout,
      :time_display,
      :unread_opened,
      :hide_warnings,
      :hide_hiatused_tags_owed,
      :ignore_unread_daily_report,
      :visible_unread,
      :favorite_notifications,
      :show_user_in_switcher,
    )
  end

  def store_tos
    current_user.tos_version = User::CURRENT_TOS_VERSION
    unless current_user.save
      flash.now[:error] = 'There was an error saving your changes. Please try again.'
      return render 'about/accept_tos'
    end

    flash[:success] = "Acceptance saved successfully. Thank you!"
    redirect_to session[:previous_url] || root_url
  end
end
