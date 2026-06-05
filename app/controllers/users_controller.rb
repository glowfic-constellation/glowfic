# frozen_string_literal: true
class UsersController < ApplicationController
  include DateSelectable
  include Taggable

  before_action :signup_prep, only: :new
  before_action :login_required, except: [:index, :show, :new, :create, :search]
  before_action :logout_required, only: [:new, :create]
  before_action :require_own_user, only: [:edit, :update, :password, :upgrade, :profile_edit]
  before_action :require_readonly_user, only: :upgrade
  before_action :check_lock, only: [:new, :create]

  def index
    @page_title = 'Users'
    @users = User.active.ordered.paginate(page: page)
  end

  def new
    @user = User.new
    return unless ENV.fetch("UPGRADES_LOCKED", nil).present?
    flash.now[:error] = "Full accounts are currently unavailable. You are welcome to sign up for a reader account."
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

    if params[:addition].to_i != 14
      signup_prep
      flash.now[:error] = "Please check your math and try again."
      render :new and return
    end

    if params[:secret] != ENV["ACCOUNT_SECRET"]
      @user.role_id = Permissible::READONLY
    elsif ENV.fetch("UPGRADES_LOCKED", nil).present?
      flash.now[:error] = "We're sorry, full accounts are currently unavailable."
      @user.role_id = Permissible::READONLY
    end

    begin
      @user.save!
    rescue ActiveRecord::RecordInvalid => e
      signup_prep
      flash.now[:error] = {
        message: "There was a problem completing your sign up.",
        array: @user.errors.full_messages,
      }
      log_error(e) unless @user.errors.present?
      render :new
    else
      flash[:success] = "User created! You have been logged in."
      session[:user_id] = @user.id
      @current_user = @user
      redirect_to root_url
    end
  end

  def show
    unless (@user = User.active.find_by(id: params[:id]))
      flash[:error] = "User could not be found."
      redirect_to users_path and return
    end

    ids = Post::Author.where(user_id: @user.id, joined: true).pluck(:post_id)
    posts = Post.where(id: ids).ordered
    posts = posts.not_ignored_by(current_user) if current_user&.hide_from_all
    @posts = posts_from_relation(posts)
    @page_title = @user.username
    @meta_og = og_data
  end

  def edit
    use_javascript('users/edit')
    @page_title = 'Edit Account'
  end

  def profile_edit
    use_javascript('users/profile_edit')
    gon.editor_class = 'layout_' + current_user.layout if current_user.layout
    gon.tinymce_css_path = helpers.stylesheet_path('tinymce')
    @page_title = 'Edit Author Profile'
  end

  def update
    store_tos and return if params[:tos_check]

    params[:user][:per_page] = -1 if params[:user].try(:[], :per_page) == 'all'

    begin
      if params.fetch(:user, {}).key?(:content_warning_ids)
        current_user.content_warnings = process_tags(ContentWarning, obj_param: :user, id_param: :content_warning_ids)
      end
      current_user.update!(user_params)
    rescue ActiveRecord::RecordInvalid => e
      render_errors(current_user, action: 'saved', now: true, class_name: 'Changes', err: e)

      use_javascript('users/edit')
      @page_title = 'Edit Account'
      render :edit
    else
      flash[:success] = "Changes saved."
      if params[:button_submit_profile]
        redirect_to user_path(current_user)
      else
        redirect_to edit_user_path(current_user)
      end
    end
  end

  def password
    unless current_user.authenticate(params[:old_password])
      flash.now[:error] = "Incorrect password entered."
      @page_title = 'Edit Account'
      render :edit and return
    end

    current_user.validate_password = true

    begin
      current_user.update!(user_params)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: "There was a problem with your changes.",
        array: current_user.errors.full_messages,
      }
      @page_title = 'Edit Account'
      render :edit
    else
      flash[:success] = "Changes saved."
      redirect_to edit_user_path(current_user)
    end
  end

  def upgrade
    if ENV.fetch("UPGRADES_LOCKED", nil).present?
      flash.now[:error] = "We're sorry, upgrades are currently disabled."
      @page_title = 'Edit Account'
      render :edit and return
    end

    unless params[:secret] == ENV["ACCOUNT_SECRET"]
      flash.now[:error] = "That is not the correct secret. Please ask someone in the community for help."
      @page_title = 'Edit Account'
      render :edit and return
    end

    unless current_user.update(role_id: nil)
      flash.now[:error] = "There was a problem updating your account."
      @page_title = 'Edit Account'
      render :edit and return
    end

    flash[:success] = "Changes saved successfully."
    redirect_to edit_user_path(current_user)
  end

  def search
    @page_title = 'Search Users'
    return unless params[:commit].present?
    response.headers['X-Robots-Tag'] = 'noindex'
    username = '%' + params[:username].to_s + '%'
    @search_results = User.active.where("username ILIKE ?", username).ordered.paginate(page: page)
  end

  def output
    flash.now[:error] = 'Please note that this page does not include edit history.'
    use_javascript('users/output')

    @day = calculate_day
    daystart = @day.beginning_of_day
    dayend = @day.end_of_day

    @posts, @replies = [Post, Reply].map do |klass|
      klass.where(user: current_user).where('created_at between ? AND ?', daystart, dayend)
    end
    @posts = @posts.ordered_by_id.pluck(:content, :editor_mode)
    @replies = @replies.order(post_id: :asc).ordered.pluck(:content, :editor_mode)

    @total = (@posts + @replies).map { |x, _| x }
    if @total.empty?
      @total = 0
    else
      @total[0] = @total[0].split.size
      @total = @total.inject { |r, e| r + e.split.size }.to_i
    end
  end

  private

  def require_own_user
    return if params[:id] == current_user.id.to_s
    flash[:error] = "You do not have permission to modify this account."
    redirect_to(continuities_path)
  end

  def require_readonly_user
    return if current_user.read_only?
    flash[:error] = "This account does not need to be upgraded."
    redirect_to edit_user_path(current_user)
  end

  def check_lock
    return unless ENV.fetch("SIGNUPS_LOCKED", nil).present?
    flash[:error] = "We're sorry, signups are currently closed."
    redirect_to(root_path)
  end

  def signup_prep
    use_javascript('users/new')
    @page_title = 'Sign Up'
  end

  def og_data
    board_ids = BoardAuthor.where(user_id: @user.id, cameo: false).select(:board_id).distinct.pluck(:board_id)
    boards = Board.where(id: board_ids).ordered.pluck(:name)
    board_count = boards.length
    if board_count > 0
      desc = "Continuity".pluralize(board_count) + ": " + generate_short(boards * ', ')
    else
      desc = "No continuities."
    end
    data = {
      url: user_url(@user),
      title: @user.username,
      description: desc,
    }
    if @user.avatar.present?
      data[:image] = {
        src: @user.avatar.url,
        width: '75',
        height: '75',
      }
    end
    data
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
      :default_hide_retired_characters,
      :default_editor,
      :moiety,
      :moiety_name,
      :profile,
      :profile_editor_mode,
      :layout,
      :time_display,
      :unread_opened,
      :visible_unread,
      :hide_from_all,
      :hide_warnings,
      :hide_hiatused_tags_owed,
      :public_bookmarks,
      :ignore_unread_daily_report,
      :favorite_notifications,
      :show_user_in_switcher,
      :default_hide_edit_delete_buttons,
      :default_hide_add_bookmark_button,
    )
  end

  def store_tos
    current_user.tos_version = User::CURRENT_TOS_VERSION
    begin
      current_user.save!
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {
        message: 'There was an error saving your changes. Please try again.',
        array: current_user.errors.full_messages,
      }
      render 'about/accept_tos'
    else
      flash[:success] = "Acceptance saved. Thank you."
      redirect_to session[:previous_url] || root_url # allow_other_host: false
    end
  end
end
