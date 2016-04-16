class PostsController < WritableController
  before_filter :login_required, :except => [:index, :show, :history]
  before_filter :find_post, :only => [:show, :history, :edit, :update, :destroy]
  before_filter :require_permission, only: [:edit, :destroy]
  before_filter :build_template_groups, :only => [:new, :show, :edit]

  def index
    @posts = Post.order('updated_at desc').includes(:board, :user, :last_user).paginate(page: page, per_page: 25)
    @page_title = "Recent Threads"
  end

  def owed
    posts_started = Post.where(user_id: current_user.id).select(:id).group(:id).map(&:id)
    posts_in = Reply.where(user_id: current_user.id).select(:post_id).group(:post_id).map(&:post_id)
    ids = posts_in + posts_started
    @posts = Post.where(id: ids.uniq).where("board_id != 4").where('status != 1').order('updated_at desc') # TODO don't hardcode things
    @posts = @posts.where('last_user_id != ?', current_user.id).includes(:board).paginate(page: page, per_page: 25)
    @posts.reject! { |post| post.last_post.user_id == current_user.id }
    @page_title = "Threads Awaiting Tag"
  end

  def unread
    @posts = Post.joins("LEFT JOIN post_views ON post_views.post_id = posts.id AND post_views.user_id = #{current_user.id}")
    @posts = @posts.joins("LEFT JOIN board_views on board_views.board_id = posts.board_id AND board_views.user_id = #{current_user.id}")
    @posts = @posts.where("post_views.user_id IS NULL OR (date_trunc('second', post_views.updated_at) < date_trunc('second', posts.updated_at) AND post_views.ignored = '0')")
    @posts = @posts.where("board_views.user_id IS NULL OR (date_trunc('second', board_views.updated_at) < date_trunc('second', posts.updated_at) AND board_views.ignored = '0')")
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
    gon.original_content = params[:post][:content]

    if params[:button_preview]
      @url = posts_path
      @method = :post
      preview
      render :action => 'preview' and return
    end

    @post = Post.new(params[:post])
    @post.user = @post.last_user = current_user

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
    render action: :flat, layout: false and return if params[:view] == 'flat'
    show_post
  end

  def history
  end

  def preview
    build_template_groups
    
    @written = Post.new(params[:post])
    @post = @written
    @written.user = current_user

    use_javascript('posts')
  end

  def edit
    use_javascript('posts')
    @image = @post.icon
    @character = @post.character
    gon.original_content = @post.content
  end

  def update
    gon.original_content = params[:post][:content]

    if params[:button_preview]
      @url = post_path(params[:id])
      @method = :put
      preview
      render :action => 'preview'
    else
      if params[:unread].present?
        @post.views.where(user_id: current_user.id).destroy_all
        flash[:success] = "Post has been marked as unread"
        redirect_to board_path(@post.board) and return
      end

      status = "complete"
      if params[:completed].present?
        if params[:completed] == "true" && !@post.completed?
          @post.status = Post::STATUS_COMPLETE
          @post.save
        elsif params[:completed] == "false" && @post.completed?
          @post.status = Post::STATUS_ACTIVE
          @post.save
          status = "in progress"
        end
        flash[:success] = "Post has been marked #{status}."
        redirect_to post_path(@post) and return
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
  end

  def destroy
    @post.destroy
    flash[:success] = "Post deleted."
    redirect_to boards_path
  end

  def search
    return unless params[:commit].present?

    @search_results = Post.order('updated_at desc').includes(:board)
    @search_results = @search_results.where(board_id: params[:board_id]) if params[:board_id].present?
    @search_results = @search_results.where(user_id: params[:author_id]) if params[:author_id].present?
    @search_results = @search_results.paginate(page: page, per_page: 25)
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
end
