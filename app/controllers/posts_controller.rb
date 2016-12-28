# frozen_string_literal: true
require 'will_paginate/array'

class PostsController < WritableController
  before_filter :login_required, except: [:index, :show, :history, :warnings, :search, :stats]
  before_filter :find_post, only: [:show, :history, :stats, :warnings, :edit, :update, :destroy]
  before_filter :require_permission, only: [:edit, :destroy]
  before_filter :build_template_groups, only: [:new, :edit]
  before_filter :build_tags, only: [:new, :edit]

  def index
    @posts = posts_from_relation(Post.order('tagged_at desc'))
    @page_title = 'Recent Threads'
  end

  def owed
    posts_started = Post.where(user_id: current_user.id).pluck('distinct id')
    posts_in = Reply.where(user_id: current_user.id).pluck('distinct post_id')
    ids = (posts_in + posts_started).uniq
    @posts = Post.where(id: ids).where('status != ?', Post::STATUS_COMPLETE).where('status != ?', Post::STATUS_ABANDONED).where('last_user_id != ?', current_user.id)
    @posts = posts_from_relation(@posts.order('tagged_at desc'))
    @show_unread = true
    @hide_quicklinks = true
    @page_title = 'Tags Owed'
  end

  def unread
    @started = (params[:started] == 'true') || (params[:started].nil? && current_user.unread_opened)
    @posts = Post.joins("LEFT JOIN post_views ON post_views.post_id = posts.id AND post_views.user_id = #{current_user.id}")
    @posts = @posts.joins("LEFT JOIN board_views on board_views.board_id = posts.board_id AND board_views.user_id = #{current_user.id}")
    @posts = @posts.where("post_views.user_id IS NULL OR (date_trunc('second', post_views.read_at) < date_trunc('second', posts.tagged_at) AND post_views.ignored = '0')")
    @posts = @posts.where("board_views.user_id IS NULL OR (date_trunc('second', board_views.read_at) < date_trunc('second', posts.tagged_at) AND board_views.ignored = '0')")
    @posts = posts_from_relation(@posts.order('tagged_at desc'), true, false)
    @posts = @posts.select { |p| p.visible_to?(current_user) }
    @posts = @posts.select { |p|  @opened_ids.include?(p.id) } if @started
    @posts = @posts.paginate(per_page: 25, page: page)
    @hide_quicklinks = true
    @page_title = @started ? 'Opened Threads' : 'Unread Threads'
  end

  def mark
    posts = Post.where(id: params[:marked_ids])
    posts.select! do |post|
      post.visible_to?(current_user)
    end
    if params[:commit] == "Mark Read"
      posts.each { |post| post.mark_read(current_user) }
      flash[:success] = posts.size.to_s + " posts marked as read."
    else
      posts.each { |post| post.ignore(current_user) }
      flash[:success] = posts.size.to_s + " posts hidden from this page."
    end
    redirect_to unread_posts_path
  end

  def hidden
    @hidden_boardviews = BoardView.where(user_id: current_user.id).where(ignored: true).includes(:board)
    hidden_post_ids = PostView.where(user_id: current_user.id).where(ignored: true).pluck('distinct post_id')
    @hidden_posts = posts_from_relation(Post.where(id: hidden_post_ids))
    @page_title = 'Hidden Posts & Boards'
  end

  def unhide
    if params[:unhide_boards].present?
      board_ids = params[:unhide_boards].map(&:to_i).compact.uniq
      views_to_update = BoardView.where(user_id: current_user.id).where(board_id: board_ids)
      views_to_update.each do |view| view.update_attributes(ignored: false) end
    end

    if params[:unhide_posts].present?
      post_ids = params[:unhide_posts].map(&:to_i).compact.uniq
      views_to_update = PostView.where(user_id: current_user.id).where(post_id: post_ids)
      views_to_update.each do |view| view.update_attributes(ignored: false) end
    end

    redirect_to hidden_posts_path
  end

  def new
    use_javascript('posts')
    @post = Post.new(character: current_user.active_character, user: current_user)
    @post.board_id = params[:board_id]
    @post.icon_id = (current_user.active_character ? current_user.active_character.icon.try(:id) : current_user.avatar_id)
    @page_title = 'New Post'
  end

  def create
    gon.original_content = params[:post][:content]
    preview(:post, posts_path) and return if params[:button_preview].present?

    @post = Post.new(params[:post])
    @post.user = @post.last_user = current_user

    create_new_tags if @post.valid?

    if @post.save
      flash[:success] = "You have successfully posted."
      redirect_to post_path(@post)
    else
      flash.now[:error] = {}
      flash.now[:error][:array] = @post.errors.full_messages
      flash.now[:error][:message] = "Your post could not be saved because of the following problems:"
      use_javascript('posts')
      build_template_groups
      build_tags
      @page_title = 'New Post'
      render :action => :new
    end
  end

  def show
    if params[:view] == 'flat'
      @replies = @post.replies
        .select('replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username')
        .joins(:user)
        .joins("LEFT OUTER JOIN characters ON characters.id = replies.character_id")
        .joins("LEFT OUTER JOIN icons ON icons.id = replies.icon_id")
        .order('id asc')
      render action: :flat, layout: false and return
    end

    show_post
  end

  def history
  end

  def stats
  end

  def preview(method, path)
    build_template_groups

    @written = Post.new(params[:post])
    @post = @written
    @written.user = current_user
    @url = path
    @method = method

    build_tags

    use_javascript('posts')
    gon.original_content = params[:post][:content] if params[:post]
    @page_title = 'Previewing: ' + @post.subject
    render action: :preview
  end

  def edit
    use_javascript('posts')
    gon.original_content = @post.content
  end

  def update
    mark_unread and return if params[:unread].present?

    require_permission

    change_status and return if params[:status].present?
    change_authors_locked and return if params[:authors_locked].present?
    preview(:put, post_path(params[:id])) and return if params[:button_preview].present?

    gon.original_content = params[:post][:content] if params[:post]
    @post.assign_attributes(params[:post])
    @post.board ||= Board.find(3)

    create_new_tags if @post.valid?

    if @post.save
      flash[:success] = "Your post has been updated."
      redirect_to post_path(@post)
    else
      flash.now[:error] = {}
      flash.now[:error][:array] = @post.errors.full_messages
      flash.now[:error][:message] = "Your post could not be saved because of the following problems:"
      use_javascript('posts')
      build_template_groups
      build_tags
      render :action => :edit
    end
  end

  def mark_unread
    if params[:at_id].present?
      reply = Reply.find(params[:at_id])
      if reply && reply.post == @post
        board_read = @post.board.last_read(current_user)
        if board_read && board_read > reply.created_at
          flash[:error] = "You have marked this continuity read more recently than that reply was written; it will not appear in your Unread posts."
          Message.create(recipient_id: 1, sender_id: 1, subject: 'Unread at failure', message: "#{current_user.username} tried to mark post #{@post.id} unread at reply #{reply.id}")
        else
          @post.mark_read(current_user, reply.created_at - 1.second, true)
        end
      end
      return redirect_to unread_posts_path
    end

    @post.views.where(user_id: current_user.id).destroy_all
    flash[:success] = "Post has been marked as unread"
    redirect_to unread_posts_path
  end

  def change_status
    begin
      new_status = Post.const_get('STATUS_'+params[:status].upcase)
    rescue NameError
      flash[:error] = "Invalid status selected."
    else
      @post.status = new_status
      @post.save
      flash[:success] = "Post has been marked #{params[:status]}."
    end
    redirect_to post_path(@post)
  end

  def change_authors_locked
    @post.authors_locked = (params[:authors_locked] == 'true')
    @post.save
    flash[:success] = "Post has been #{@post.authors_locked? ? 'locked to' : 'unlocked from'} current authors."
    redirect_to post_path(@post)
  end

  def destroy
    @post.destroy
    flash[:success] = "Post deleted."
    redirect_to boards_path
  end

  def search
    @page_title = 'Browse Posts'
    return unless params[:commit].present?

    @search_results = Post.order('tagged_at desc').includes(:board)
    @search_results = @search_results.where(board_id: params[:board_id]) if params[:board_id].present?
    @search_results = @search_results.where(id: Setting.find(params[:setting_id]).post_tags.pluck(:post_id)) if params[:setting_id].present?
    if params[:author_id].present?
      post_ids = Reply.where(user_id: params[:author_id]).pluck('distinct post_id')
      where = Post.where(user_id: params[:author_id]).where(id: post_ids).where_values.reduce(:or)
      @search_results = @search_results.where(where)
    end
    if params[:character_id].present?
      post_ids = Reply.where(character_id: params[:character_id]).pluck('distinct post_id')
      where = Post.where(character_id: params[:character_id]).where(id: post_ids).where_values.reduce(:or)
      @search_results = @search_results.where(where)
    end
    if params[:completed].present?
      @search_results = @search_results.where(status: Post::STATUS_COMPLETE)
    end
    @search_results = @search_results.paginate(page: page, per_page: 25)
  end

  def warnings
    if logged_in?
      @post.hide_warnings_for(current_user)
      flash[:success] = "Content warnings have been hidden for this thread. Proceed at your own risk."
    else
      session[:ignore_warnings] = true
      flash[:success] = "All content warnings have been hidden. Proceed at your own risk."
    end
    redirect_to post_path(@post, page: page, per_page: per_page)
  end

  private

  def find_post
    @post = Post.find_by_id(params[:id])

    unless @post
      flash[:error] = "Post could not be found."
      redirect_to boards_path and return
    end

    unless @post.visible_to?(current_user)
      flash[:error] = "You do not have permission to view this post."
      redirect_to boards_path and return
    end

    @page_title = @post.subject
  end

  def require_permission
    unless @post.editable_by?(current_user) || @post.metadata_editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this post."
      redirect_to post_path(@post)
    end
  end

  def build_tags
    @settings = Setting.all
    @warnings = ContentWarning.all
    @tags = Tag.where(type: nil)
    faked = Struct.new(:name, :id)

    if @post.try(:setting_ids)
      new_tags = @post.setting_ids.reject { |t| t.blank? || !t.to_i.zero? }
      @settings += new_tags.map { |t| faked.new(t, t) }
    end

    if @post.try(:warning_ids)
      new_tags = @post.warning_ids.reject { |t| t.blank? || !t.to_i.zero? }
      @warnings += new_tags.map { |t| faked.new(t, t) }
    end

    if @post.try(:tag_ids)
      new_tags = @post.tag_ids.reject { |t| t.blank? || !t.to_i.zero? }
      @tags += new_tags.map { |t| faked.new(t, t) }
    end
  end

  def create_new_tags
    if @post.setting_ids.present?
      tags = @post.setting_ids.select { |id| id.to_i.zero? }.reject(&:blank?).compact.uniq
      @post.setting_ids -= tags
      existing_tags = Setting.where(name: tags)
      @post.setting_ids += existing_tags.map(&:id)
      tags -= existing_tags.map(&:name)
      @post.setting_ids += tags.map { |tag| Setting.create(user: current_user, name: tag).id }
    end

    if @post.warning_ids.present?
      tags = @post.warning_ids.select { |id| id.to_i.zero? }.reject(&:blank?).compact.uniq
      @post.warning_ids -= tags
      existing_tags = ContentWarning.where(name: tags)
      @post.warning_ids += existing_tags.map(&:id)
      tags -= existing_tags.map(&:name)
      @post.warning_ids += tags.map { |tag| ContentWarning.create(user: current_user, name: tag).id }
    end

    if @post.tag_ids.present?
      tags = @post.tag_ids.select { |id| id.to_i.zero? }.reject(&:blank?).compact.uniq
      @post.tag_ids -= tags
      existing_tags = Tag.where(name: tags, type: nil)
      @post.tag_ids += existing_tags.map(&:id)
      tags -= existing_tags.map(&:name)
      @post.tag_ids += tags.map { |tag| Tag.create(user: current_user, name: tag).id }
    end
  end
end
