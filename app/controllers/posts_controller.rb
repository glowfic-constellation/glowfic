# frozen_string_literal: true
require 'will_paginate/array'

class PostsController < WritableController
  include Taggable

  before_action :login_required, except: [:index, :show, :history, :warnings, :search, :stats]
  before_action :find_post, only: [:show, :history, :stats, :warnings, :edit, :update, :destroy]
  before_action :require_permission, only: [:edit]
  before_action :require_import_permission, only: [:new, :create]
  before_action :editor_setup, only: [:new, :edit]

  def index
    @posts = posts_from_relation(Post.ordered)
    @page_title = 'Recent Threads'
  end

  def owed
    @show_unread = true
    @hide_quicklinks = true
    @page_title = 'Replies Owed'

    ids = PostAuthor.where(user_id: current_user.id)

    if params[:view] == 'hidden'
      ids = ids.where(can_owe: false)
    else
      ids = ids.where(can_owe: true)
    end

    ids = ids.group(:post_id).pluck(:post_id)
    @posts = Post.where(id: ids).where.not(status: [Post::STATUS_COMPLETE, Post::STATUS_ABANDONED])
    @posts = @posts.where.not(last_user: current_user) unless params[:view] == 'hidden'
    @posts = @posts.where.not(status: Post::STATUS_HIATUS).where('tagged_at > ?', 1.month.ago) if current_user.hide_hiatused_tags_owed?
    @posts = posts_from_relation(@posts.ordered)
  end

  def unread
    @started = (params[:started] == 'true') || (params[:started].nil? && current_user.unread_opened)
    @posts = Post.joins("LEFT JOIN post_views ON post_views.post_id = posts.id AND post_views.user_id = #{current_user.id}")
    @posts = @posts.joins("LEFT JOIN board_views on board_views.board_id = posts.board_id AND board_views.user_id = #{current_user.id}")
    @posts = @posts.where("post_views.user_id IS NULL OR ((post_views.read_at IS NULL OR (date_trunc('second', post_views.read_at) < date_trunc('second', posts.tagged_at))) AND post_views.ignored = '0')")
    @posts = @posts.where("board_views.user_id IS NULL OR ((board_views.read_at IS NULL OR (date_trunc('second', board_views.read_at) < date_trunc('second', posts.tagged_at))) AND board_views.ignored = '0')")
    @posts = posts_from_relation(@posts.ordered, with_pagination: false)
    @posts = @posts.select { |p| @opened_ids.include?(p.id) } if @started
    @posts = @posts.paginate(per_page: 25, page: page)
    @hide_quicklinks = true
    @page_title = @started ? 'Opened Threads' : 'Unread Threads'
    use_javascript('posts/unread')
  end

  def mark
    posts = Post.where(id: params[:marked_ids])
    posts = posts.visible_to(current_user)

    if params[:commit] == "Mark Read"
      posts.each { |post| post.mark_read(current_user) }
      flash[:success] = "#{posts.size} #{'post'.pluralize(posts.size)} marked as read."
    elsif params[:commit] == "Remove from Replies Owed"
      posts.each { |post| post.opt_out_of_owed(current_user) }
      flash[:success] = "#{posts.size} #{'post'.pluralize(posts.size)} removed from replies owed."
      redirect_to owed_posts_path and return
    elsif params[:commit] == "Show in Replies Owed"
      posts.each { |post| post.opt_in_to_owed(current_user) }
      flash[:success] = "#{posts.size} #{'post'.pluralize(posts.size)} added to replies owed."
      redirect_to owed_posts_path and return
    else
      posts.each { |post| post.ignore(current_user) }
      flash[:success] = "#{posts.size} #{'post'.pluralize(posts.size)} hidden from this page."
    end
    redirect_to unread_posts_path
  end

  def hidden
    @hidden_boardviews = BoardView.where(user_id: current_user.id).where(ignored: true).includes(:board)
    hidden_post_ids = PostView.where(user_id: current_user.id).where(ignored: true).select(:post_id).distinct.pluck(:post_id)
    @hidden_posts = posts_from_relation(Post.where(id: hidden_post_ids).ordered)
    @page_title = 'Hidden Posts & Boards'
  end

  def unhide
    if params[:unhide_boards].present?
      board_ids = params[:unhide_boards].map(&:to_i).compact.uniq
      views_to_update = BoardView.where(user_id: current_user.id).where(board_id: board_ids)
      views_to_update.each do |view| view.update(ignored: false) end
    end

    if params[:unhide_posts].present?
      post_ids = params[:unhide_posts].map(&:to_i).compact.uniq
      views_to_update = PostView.where(user_id: current_user.id).where(post_id: post_ids)
      views_to_update.each do |view| view.update(ignored: false) end
    end

    redirect_to hidden_posts_path
  end

  def new
    @post = Post.new(character: current_user.active_character, user: current_user)
    @post.board_id = params[:board_id]
    @post.section_id = params[:section_id]
    @post.icon_id = (current_user.active_character ? current_user.active_character.default_icon.try(:id) : current_user.avatar_id)
    @page_title = 'New Post'

    @permitted_authors -= [current_user]
    if @post.board && !@post.board.open_to_anyone?
      @author_ids = @post.board.writer_ids - [current_user.id]
      @authors_from_board = true
    end
  end

  def create
    import_thread and return if params[:button_import].present?
    preview and return if params[:button_preview].present?

    @post = current_user.posts.new(post_params)
    @post.settings = process_tags(Setting, :post, :setting_ids)
    @post.content_warnings = process_tags(ContentWarning, :post, :content_warning_ids)
    @post.labels = process_tags(Label, :post, :label_ids)

    unless @post.save
      flash.now[:error] = {}
      flash.now[:error][:array] = @post.errors.full_messages
      flash.now[:error][:message] = "Your post could not be saved because of the following problems:"
      editor_setup
      @page_title = 'New Post'
      render :new and return
    end

    flash[:success] = "You have successfully posted."
    redirect_to post_path(@post)
  end

  def show
    render :flat, layout: false and return if params[:view] == 'flat'
    show_post
  end

  def history
  end

  def stats
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
    preview and return if params[:button_preview].present?

    @post.assign_attributes(post_params)
    @post.board ||= Board.find(3)
    settings = process_tags(Setting, :post, :setting_ids)
    warnings = process_tags(ContentWarning, :post, :content_warning_ids)
    labels = process_tags(Label, :post, :label_ids)

    if current_user.id != @post.user_id && @post.audit_comment.blank? && !@post.author_ids.include?(current_user.id)
      flash[:error] = "You must provide a reason for your moderator edit."
      editor_setup
      render :edit and return
    end
    @post.audit_comment = nil if @post.changes.empty? # don't save an audit for a note and no changes

    begin
      Post.transaction do
        @post.settings = settings
        @post.content_warnings = warnings
        @post.labels = labels
        @post.save!
      end

      flash[:success] = "Your post has been updated."
      redirect_to post_path(@post)
    rescue ActiveRecord::RecordInvalid
      flash.now[:error] = {}
      flash.now[:error][:array] = @post.errors.full_messages
      flash.now[:error][:message] = "Your post could not be saved because of the following problems:"
      editor_setup
      render :edit
    end
  end

  def destroy
    unless @post.deletable_by?(current_user)
      flash[:error] = "You do not have permission to modify this post."
      redirect_to post_path(@post) and return
    end

    begin
      @post.destroy!
      flash[:success] = "Post deleted."
      redirect_to boards_path
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {}
      flash[:error][:message] = "Post could not be deleted."
      flash[:error][:array] = @post.errors.full_messages
      redirect_to post_path(@post)
    end
  end

  def search
    @page_title = 'Search Posts'
    use_javascript('posts/search')

    # don't start blank if the parameters are set
    @setting = Setting.where(id: params[:setting_id]) if params[:setting_id].present?
    @character = Character.where(id: params[:character_id]) if params[:character_id].present?
    @user = User.where(id: params[:author_id]).ordered if params[:author_id].present?
    @board = Board.where(id: params[:board_id]) if params[:board_id].present?

    return unless params[:commit].present?

    @search_results = Post.ordered
    @search_results = @search_results.where(board_id: params[:board_id]) if params[:board_id].present?
    @search_results = @search_results.where(id: Setting.find(params[:setting_id]).post_tags.pluck(:post_id)) if params[:setting_id].present?
    @search_results = @search_results.search(params[:subject]).where('LOWER(subject) LIKE ?', "%#{params[:subject].downcase}%") if params[:subject].present?
    @search_results = @search_results.where(status: Post::STATUS_COMPLETE) if params[:completed].present?
    if params[:author_id].present?
      post_ids = nil
      params[:author_id].each do |author_id|
        author_posts = PostAuthor.where(user_id: author_id, joined: true).pluck(:post_id)
        if post_ids.nil?
          post_ids = author_posts
        else
          post_ids &= author_posts
        end
        break if post_ids.empty?
      end
      @search_results = @search_results.where(id: post_ids.uniq)
    end
    if params[:character_id].present?
      arel = Post.arel_table
      post_ids = Reply.where(character_id: params[:character_id]).select(:post_id).distinct.pluck(:post_id)
      where = arel[:character_id].eq(params[:character_id]).or(arel[:id].in(post_ids))
      @search_results = @search_results.where(where)
    end
    @search_results = posts_from_relation(@search_results).paginate(page: page, per_page: 25)
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

  def preview
    @post ||= Post.new(user: current_user)
    @post.assign_attributes(post_params(false))
    @post.board ||= Board.find_by_id(3)

    @author_ids = params.fetch(:post, {}).fetch(:unjoined_author_ids, [])
    @viewer_ids = params.fetch(:post, {}).fetch(:viewer_ids, [])
    @settings = process_tags(Setting, :post, :setting_ids)
    @content_warnings = process_tags(ContentWarning, :post, :content_warning_ids)
    @labels = process_tags(Label, :post, :label_ids)

    @written = @post
    editor_setup
    @page_title = 'Previewing: ' + @post.subject.to_s
    render :preview
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

    @post.views.where(user_id: current_user.id).first.try(:update, read_at: nil)
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
      if @post.save
        flash[:success] = "Post has been marked #{params[:status]}."
      else
        flash[:error] = {}
        flash[:error][:message] = "Status could not be updated."
        flash[:error][:array] = @post.errors.full_messages
      end
    end
    redirect_to post_path(@post)
  end

  def change_authors_locked
    @post.authors_locked = (params[:authors_locked] == 'true')
    if @post.save
      flash[:success] = "Post has been #{@post.authors_locked? ? 'locked to' : 'unlocked from'} current authors."
    else
      flash[:error] = {}
      flash[:error][:message] = "Post could not be updated."
      flash[:error][:array] = @post.errors.full_messages
    end
    redirect_to post_path(@post)
  end

  def editor_setup
    super
    @permitted_authors = User.ordered - (@post.try(:joined_authors) || [])
    @author_ids = post_params[:unjoined_author_ids].reject(&:blank?).map(&:to_i) if post_params.key?(:unjoined_author_ids)
    @author_ids ||= @post.try(:unjoined_author_ids) || []
  end

  def import_thread
    importer = PostImporter.new(params[:dreamwidth_url])
    importer.import(params[:board_id], current_user.id, section_id: params[:section_id], status: params[:status], threaded: params[:threaded])
    flash[:success] = "Post has begun importing. You will be updated on progress via site message."
    redirect_to posts_path
  rescue PostImportError => e
    flash.now[:error] = e.api_error
    params[:view] = 'import'
    editor_setup
    render :new
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

  def require_import_permission
    return unless params[:view] == 'import' || params[:button_import].present?
    unless current_user.has_permission?(:import_posts)
      flash[:error] = "You do not have access to this feature."
      redirect_to new_post_path
    end
  end

  def post_params(include_associations=true)
    allowed_params = [
      :board_id,
      :section_id,
      :privacy,
      :subject,
      :description,
      :content,
      :character_id,
      :icon_id,
      :character_alias_id,
      :authors_locked,
      :audit_comment
    ]

    # prevents us from setting (and saving) associations on preview()
    if include_associations
      allowed_params << {
        unjoined_author_ids: [],
        viewer_ids: []
      }
    end

    params.fetch(:post, {}).permit(allowed_params)
  end
end
