class PostsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :history]
  before_filter :find_post, :only => [:show, :history, :edit, :update, :destroy]
  before_filter :require_permission, only: [:edit, :destroy]
  before_filter :build_template_groups, :only => [:new, :show, :edit, :preview]

  def index
    @posts = Post.order('updated_at desc').limit(25).includes(:board)
    @page_title = "Recent Threads"
  end

  def owed
    posts_started = Post.where(user_id: current_user.id).select(:id).group(:id).map(&:id)
    posts_in = Reply.where(user_id: current_user.id).select(:post_id).group(:post_id).map(&:post_id)
    ids = posts_in + posts_started
    @posts = Post.where(id: ids.uniq).where("board_id != 4").order('updated_at desc').limit(25).includes(:board)
    @posts.reject! { |post| post.last_post.user_id == current_user.id }
    @page_title = "Threads Awaiting Tag"
  end

  def unread
    @posts = Post.joins("LEFT JOIN post_views ON post_views.post_id = posts.id AND post_views.user_id = #{current_user.id}")
    @posts = @posts.joins("LEFT JOIN board_views on board_views.board_id = posts.board_id AND board_views.user_id = #{current_user.id}")
    @posts = @posts.where("post_views.user_id IS NULL OR (post_views.updated_at < posts.updated_at AND post_views.ignored = '0')")
    @posts = @posts.where("board_views.user_id IS NULL OR (board_views.updated_at < posts.updated_at AND post_views.ignored = '0')")
    @posts = @posts.order('updated_at desc').includes(:board)
    @page_title = "Unread Threads"
  end

  def mark    
    posts = Post.where(id: params[:marked_ids])
    posts.select! do |post|
      post.visible_to?(current_user)
    end
    if params[:commit] == "Mark Read"
      posts.each { |post| post.mark_read(current_user) }
      flash[:success] = posts.count.to_s + " posts marked as read."
    else
      posts.each { |post| post.ignore(current_user) }
      flash[:success] = posts.count.to_s + " posts hidden from this page."
    end
    redirect_to unread_posts_path
  end

  def new
    use_javascript('posts')
    @post = Post.new(character: current_user.active_character, user: current_user)
    @post.board_id = params[:board_id]
    @character = current_user.active_character
    @image = @character ? @character.icon : current_user.avatar
    @post.icon_id = @image.try(:id)
  end

  def create
    @post = Post.new(params[:post].merge(user: current_user))

    if @post.save
      flash[:success] = "You have successfully posted."
      redirect_to post_path(@post)
    else
      flash.now[:error] = @post.errors.full_messages.to_s
      @image = @post.icon
      @character = @post.character
      use_javascript('posts')
      build_template_groups
      render :action => :new
    end
  end

  def show
    @threaded = false
    replies = if @post.replies.where('thread_id is not null').count > 1
      @threaded = true
      if params[:thread_id].present?
        @replies = @post.replies.where(thread_id: params[:thread_id])
      else
        @post.replies.where('id = thread_id')
      end
    else
      @post.replies
    end

    per = per_page > 0 ? per_page : replies.count
    @replies = replies.order('id asc').paginate(page: page, per_page: per)
    redirect_to post_path(@post, page: @replies.total_pages, per_page: per) and return if page > @replies.total_pages
    use_javascript('paginator')

    if logged_in?
      use_javascript('posts')
      
      active_char = @post.last_character_for(current_user) || current_user.active_character
      @reply = Reply.new(post: @post, 
        character: active_char,
        user: current_user, 
        icon: active_char.try(:icon))
      @character = active_char
      @image = @character ? @character.icon : current_user.avatar

      at_time = if @replies.empty?
        @post.updated_at
      else
        @replies.map(&:updated_at).max
      end
      @post.mark_read(current_user, at_time) unless @post.board.ignored_by?(current_user)
    end
  end

  def history
  end

  def preview
    if params[:post]
      @written = Post.new(params[:post])
      @post = @written
      @url = params[:post_id] ? post_path(params[:post_id]) : posts_path
      @method = params[:post_id] ? :put : :post
    elsif params[:reply]
      @written = Reply.new(params[:reply])
      @post = @written.post
      @url = params[:reply_id] ? reply_path(params[:reply_id]) : replies_path
      @method = params[:reply_id] ? :put : :post
    end
    @written.user = current_user

    use_javascript('posts')
  end

  def edit
    use_javascript('posts')
    @image = @post.icon
    @character = @post.character
  end

  def update
    if params[:unread].present?
      @post.views.where(user_id: current_user.id).destroy_all
      flash[:success] = "Post has been marked as unread"
      redirect_to board_path(@post.board) and return
    end

    require_permission

    @post.update_attributes(params[:post])
    @post.board ||= Board.find(3)
    if @post.save
      flash[:success] = "Your post has been updated."
      redirect_to post_path(@post)
    else
      flash.now[:error] = @post.errors.full_messages
      @image = @post.replies[0].icon
      @character = @post.replies[0].character
      use_javascript('posts')
      build_template_groups
      render :action => :new
    end
  end

  def destroy
    @post.destroy
    flash[:success] = "Post deleted."
    redirect_to boards_path
  end

  def search
    return unless params[:commit].present?

    @search_results = Post.order('updated_at desc').limit(25)
    @search_results = @search_results.where(board_id: params[:board_id]) if params[:board_id].present?
    @search_results = @search_results.where(user_id: params[:author_id]) if params[:author_id].present?
    @search_results = @search_results.paginate(page: page, per_page: per_page > 0 ? per_page : 25)
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
    unless @post.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this post."
      redirect_to post_path(@post)
    end
  end

  def build_template_groups
    return unless logged_in?
    templates = current_user.templates.sort_by(&:name)
    faked = Struct.new(:name, :id, :ordered_characters)
    templateless = faked.new('Templateless', nil, current_user.characters.where(:template_id => nil).to_a)
    @templates = templates + [templateless]

    gon.current_user = current_user.gon_attributes
    gon.character_path = character_user_path(current_user)
  end
end
