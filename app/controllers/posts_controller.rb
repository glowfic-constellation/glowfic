# frozen_string_literal: true
require 'will_paginate/array'

class PostsController < WritableController
  SCRAPE_USERS = [1, 2, 3, 8, 24, 31]
  before_filter :login_required, except: [:index, :show, :history, :warnings, :search, :stats]
  before_filter :find_post, only: [:show, :history, :stats, :warnings, :edit, :update, :destroy]
  before_filter :require_permission, only: [:edit, :destroy]
  before_filter :editor_setup, only: [:new, :edit]

  def index
    @posts = posts_from_relation(Post.order('tagged_at desc'))
    @page_title = 'Recent Threads'
  end

  def owed
    posts_started = Post.where(user_id: current_user.id).pluck('distinct id')
    posts_in = Reply.where(user_id: current_user.id).pluck('distinct post_id')
    ids = (posts_in + posts_started).uniq
    @posts = Post.where(id: ids).where('status != ?', Post::STATUS_COMPLETE).where('status != ?', Post::STATUS_ABANDONED).where('last_user_id != ?', current_user.id)
    @posts = @posts.where('status != ?', Post::STATUS_HIATUS).where('tagged_at > ?', 1.month.ago) if current_user.hide_hiatused_tags_owed?
    @posts = posts_from_relation(@posts.order('tagged_at desc'))
    @show_unread = true
    @hide_quicklinks = true
    @page_title = 'Tags Owed'
  end

  def unread
    @started = (params[:started] == 'true') || (params[:started].nil? && current_user.unread_opened)
    @posts = Post.joins("LEFT JOIN post_views ON post_views.post_id = posts.id AND post_views.user_id = #{current_user.id}")
    @posts = @posts.joins("LEFT JOIN board_views on board_views.board_id = posts.board_id AND board_views.user_id = #{current_user.id}")
    @posts = @posts.where("post_views.user_id IS NULL OR  ((post_views.read_at IS NULL OR (date_trunc('second', post_views.read_at) < date_trunc('second', posts.tagged_at))) AND post_views.ignored = '0')")
    @posts = @posts.where("board_views.user_id IS NULL OR ((board_views.read_at IS NULL OR (date_trunc('second', board_views.read_at) < date_trunc('second', posts.tagged_at))) AND board_views.ignored = '0')")
    @posts = posts_from_relation(@posts.order('tagged_at desc'), true, false)
    @posts = @posts.select { |p| p.visible_to?(current_user) }
    @posts = @posts.select { |p|  @opened_ids.include?(p.id) } if @started
    @posts = @posts.paginate(per_page: 25, page: page)
    @hide_quicklinks = true
    @page_title = @started ? 'Opened Threads' : 'Unread Threads'
  end

  def mark
    posts = Post.where(id: params[:marked_ids])
    posts = posts.select do |post|
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
    @post = Post.new(character: current_user.active_character, user: current_user)
    @post.board_id = params[:board_id]
    @post.section_id = params[:section_id]
    @post.icon_id = (current_user.active_character ? current_user.active_character.default_icon.try(:id) : current_user.avatar_id)
    @page_title = 'New Post'
  end

  def create
    import_thread and return if params[:button_import].present?

    @post = Post.new(params[:post])
    @post.user = current_user
    preview and return if params[:button_preview].present?

    create_new_tags if @post.valid?

    if @post.save
      flash[:success] = "You have successfully posted."
      redirect_to post_path(@post)
    else
      flash.now[:error] = {}
      flash.now[:error][:array] = @post.errors.full_messages
      flash.now[:error][:message] = "Your post could not be saved because of the following problems:"
      editor_setup
      @page_title = 'New Post'
      render :action => :new
    end
  end

  def show
    render action: :flat, layout: false and return if params[:view] == 'flat'
    show_post
  end

  def history
  end

  def stats
  end

  def preview
    @written = @post
    editor_setup
    @page_title = 'Previewing: ' + @post.subject.to_s
    render action: :preview
  end

  def edit
  end

  def update
    mark_unread and return if params[:unread].present?
    mark_hidden and return if params[:hidden].present?

    require_permission
    return if performed?

    change_status and return if params[:status].present?
    change_authors_locked and return if params[:authors_locked].present?

    @post.assign_attributes(params[:post])
    @post.board ||= Board.find(3)

    preview and return if params[:button_preview].present?

    create_new_tags if @post.valid?

    if @post.save
      flash[:success] = "Your post has been updated."
      redirect_to post_path(@post)
    else
      flash.now[:error] = {}
      flash.now[:error][:array] = @post.errors.full_messages
      flash.now[:error][:message] = "Your post could not be saved because of the following problems:"
      editor_setup
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
          Message.send_site_message(1, 'Unread at failure', "#{current_user.username} tried to mark post #{@post.id} unread at reply #{reply.id}")
        else
          @post.mark_read(current_user, reply.created_at - 1.second, true)
          flash[:success] = "Post has been marked as read until reply ##{reply.id}."
        end
      end
      return redirect_to unread_posts_path
    end

    @post.views.where(user_id: current_user.id).first.try(:update_attributes, read_at: nil)
    flash[:success] = "Post has been marked as unread"
    redirect_to unread_posts_path
  end

  def mark_hidden
    if params[:hidden].to_s == 'true'
      @post.ignore(current_user)
      flash[:success] = "Post has been hidden"
    else
      @post.unignore(current_user)
      flash[:success] = "Post has been unhidden"
    end
    redirect_to post_path(@post)
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
    @page_title = 'Search Posts'
    use_javascript('posts/search')

    # don't start blank if the parameters are set
    @setting = Setting.where(id: params[:setting_id]) if params[:setting_id].present?
    @character = Character.where(id: params[:character_id]) if params[:character_id].present?
    @user = User.where(id: params[:author_id]) if params[:author_id].present?
    @board = Board.where(id: params[:board_id]) if params[:board_id].present?

    return unless params[:commit].present?

    @search_results = Post.order('tagged_at desc').includes(:board)
    @search_results = @search_results.where(board_id: params[:board_id]) if params[:board_id].present?
    @search_results = @search_results.where(id: Setting.find(params[:setting_id]).post_tags.pluck(:post_id)) if params[:setting_id].present?
    @search_results = @search_results.search(params[:subject]).where('LOWER(subject) LIKE ?', "%#{params[:subject].downcase}%") if params[:subject].present?
    @search_results = @search_results.where(status: Post::STATUS_COMPLETE) if params[:completed].present?
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
    @search_results = @search_results.paginate(page: page, per_page: 25)
    if @search_results.total_pages <= 1
      @search_results = @search_results.select {|post| post.visible_to?(current_user)}.paginate(page: page, per_page: 25)
    end
  end

  def warnings
    if logged_in?
      @post.hide_warnings_for(current_user)
      flash[:success] = "Content warnings have been hidden for this thread. Proceed at your own risk. Please be aware that this will reset if new warnings are added later."
    else
      session[:ignore_warnings] = true
      flash[:success] = "All content warnings have been hidden. Proceed at your own risk."
    end
    params = {}
    params[:page] = page unless page.to_s == '1'
    params[:per_page] = per_page unless per_page.to_s == (current_user.try(:per_page) || 25).to_s
    redirect_to post_path(@post, params)
  end

  private

  def import_thread
    unless SCRAPE_USERS.include?(current_user.id)
      flash[:error] = "You do not have access to this feature."
      editor_setup
      return render action: :new
    end

    unless valid_dreamwidth_url?(params[:dreamwidth_url])
      flash[:error] = "Invalid URL provided."
      params[:view] = 'import'
      use_javascript('posts')
      return render action: :new
    end

    if (missing = missing_usernames(params[:dreamwidth_url])).present?
      flash[:error] = {}
      flash[:error][:message] = "The following usernames were not recognized. Please have the correct author create a character with the correct screenname, or contact Marri if you wish to map a particular screenname to 'your base account posting without a character'."
      flash[:error][:array] = missing
      return render action: :new
    end

    Resque.enqueue(ScrapePostJob, params[:dreamwidth_url], params[:board_id], params[:section_id], params[:status], params[:threaded], current_user.id)
    flash[:success] = "Post has begun importing. You will be updated on progress via site message."
    redirect_to posts_path
  end

  def missing_usernames(url)
    require "#{Rails.root}/lib/post_scraper"
    doc = Nokogiri::HTML(HTTParty.get(url).body)
    usernames = doc.css('.poster span.ljuser b').map(&:text).uniq
    usernames -= PostScraper::BASE_ACCOUNTS.keys
    poster_names = doc.css('.entry-poster span.ljuser b')
    usernames -= [poster_names.last.text] if poster_names.count > 1
    usernames - Character.where(screenname: usernames).pluck(:screenname)
  end

  def valid_dreamwidth_url?(url)
    # this is simply checking for a properly formatted Dreamwidth URL
    # errors when actually querying the URL are handled by ScrapePostJob
    return false if url.blank?
    return false unless params[:dreamwidth_url].include?('dreamwidth')
    parsed_url = URI.parse(url)
    return false unless parsed_url.host
    parsed_url.host.ends_with?('dreamwidth.org')
  rescue URI::InvalidURIError
    false
  end

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
    faked = Struct.new(:name, :id)
    @settings = build_subtags(Setting, :setting_ids, faked)
    @warnings = build_subtags(ContentWarning, :warning_ids, faked)
    @tags = build_subtags(Label, :label_ids, faked)
  end

  def build_subtags(klass, method, faked)
    return [] unless @post

    existing_saved = @post.send(klass.to_s.underscore.pluralize) || []
    return existing_saved unless @post.send(method)

    existing_unsaved = klass.where(id: @post.send(method) - existing_saved.map { |es| es.id.to_s })
    new_tags = @post.send(method).reject { |t| t.blank? || !t.to_i.zero? }
    existing_saved + existing_unsaved + new_tags.map { |t| faked.new(t, t) }
  end

  def create_new_tags
    if @post.setting_ids.present?
      tags = @post.setting_ids.select { |id| id.to_i.zero? }.reject(&:blank?).uniq
      @post.setting_ids -= tags
      existing_tags = Setting.where(name: tags)
      @post.setting_ids += existing_tags.map(&:id)
      tags -= existing_tags.map(&:name)
      @post.setting_ids += tags.map { |tag| Setting.create(user: current_user, name: tag).id }
    end

    if @post.warning_ids.present?
      tags = @post.warning_ids.select { |id| id.to_i.zero? }.reject(&:blank?).uniq
      @post.warning_ids -= tags
      existing_tags = ContentWarning.where(name: tags)
      @post.warning_ids += existing_tags.map(&:id)
      tags -= existing_tags.map(&:name)
      @post.warning_ids += tags.map { |tag| ContentWarning.create(user: current_user, name: tag).id }
    end

    if @post.label_ids.present?
      tags = @post.label_ids.select { |id| id.to_i.zero? }.reject(&:blank?).uniq
      @post.label_ids -= tags
      existing_tags = Label.where(name: tags)
      @post.label_ids += existing_tags.map(&:id)
      tags -= existing_tags.map(&:name)
      @post.label_ids += tags.map { |tag| Label.create(user: current_user, name: tag).id }
    end
  end

  def editor_setup
    use_javascript('posts/editor')
    build_template_groups
    build_tags
  end
end
