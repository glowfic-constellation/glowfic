class PostsController < WritableController
  before_filter :login_required, except: [:index, :show, :history, :search, :stats]
  before_filter :find_post, only: [:show, :history, :stats, :edit, :update, :destroy]
  before_filter :require_permission, only: [:edit, :destroy]
  before_filter :build_template_groups, only: [:new, :show, :edit]
  before_filter :build_tags, only: [:new, :edit]

  def index
    @posts = Post.order('tagged_at desc').includes(:board, :user, :last_user).paginate(page: page, per_page: 25)
    @page_title = "Recent Threads"
  end

  def owed
    posts_started = Post.where(user_id: current_user.id).select(:id).group(:id).map(&:id)
    posts_in = Reply.where(user_id: current_user.id).select(:post_id).group(:post_id).map(&:post_id)
    ids = posts_in + posts_started
    @posts = Post.where(id: ids.uniq).where("board_id != 4").where('status != 1').order('tagged_at desc') # TODO don't hardcode things
    @posts = @posts.where('last_user_id != ?', current_user.id).includes(:board).paginate(page: page, per_page: 25)
    @page_title = "Tags Owed"
    @show_unread = true
  end

  def unread
    @posts = Post.joins("LEFT JOIN post_views ON post_views.post_id = posts.id AND post_views.user_id = #{current_user.id}")
    @posts = @posts.joins("LEFT JOIN board_views on board_views.board_id = posts.board_id AND board_views.user_id = #{current_user.id}")
    @posts = @posts.where("post_views.user_id IS NULL OR (date_trunc('second', post_views.updated_at) < date_trunc('second', posts.tagged_at) AND post_views.ignored = '0')")
    @posts = @posts.where("board_views.user_id IS NULL OR (date_trunc('second', board_views.updated_at) < date_trunc('second', posts.tagged_at) AND board_views.ignored = '0')")
    @posts = @posts.order('tagged_at desc').includes(:board, :user, :last_user).paginate(per_page: 25, page: page)
    @opened_ids = PostView.where(user_id: current_user.id).select(:post_id).map(&:post_id)
    @page_title = "Unread Threads"
    @show_unread = @conditional_unread = true
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

  def hidden
    @hidden_boardviews = BoardView.where(user_id: current_user.id).where(ignored: true).includes(:board)
    @hidden_postviews = PostView.where(user_id: current_user.id).where(ignored: true).includes(:post)
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
    @character = current_user.active_character
    @image = @character ? @character.icon : current_user.avatar
    @post.icon_id = @image.try(:id)
  end

  def create
    reorder_sections and return if params[:commit] == "reorder"

    gon.original_content = params[:post][:content]
    preview(:post, posts_path) and return if params[:button_preview].present?

    @post = Post.new(params[:post])
    @post.user = @post.last_user = current_user

    # create new tags iff post is valid
    if @post.valid? && @post.tag_ids.present?
      tags = @post.tag_ids.select { |id| id.to_i.zero? }.reject(&:blank?).compact.uniq
      @post.tag_ids -= tags
      @post.tag_ids += tags.map { |tag| Tag.create(user: current_user, name: tag).id }
    end

    if @post.save
      flash[:success] = "You have successfully posted."
      redirect_to post_path(@post)
    else
      flash.now[:error] = {}
      flash.now[:error][:array] = @post.errors.full_messages
      flash.now[:error][:message] = "Your post could not be saved because of the following problems:"
      @image = @post.icon
      @character = @post.character
      use_javascript('posts')
      build_template_groups
      build_tags
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

  def preview(method, path)
    build_template_groups
    
    @written = Post.new(params[:post])
    @post = @written
    @written.user = current_user
    @character = @post.character
    @url = path
    @method = method

    use_javascript('posts')
    gon.original_content = params[:post][:content] if params[:post]
    render action: 'preview'
  end

  def edit
    use_javascript('posts')
    @image = @post.icon
    @character = @post.character
    gon.original_content = @post.content
  end

  def update
    mark_unread and return if params[:unread].present?
    change_status and return if params[:status].present?

    require_permission
    preview(:put, post_path(params[:id])) and return if params[:button_preview].present?

    gon.original_content = params[:post][:content] if params[:post]
    @post.assign_attributes(params[:post])
    @post.board ||= Board.find(3)

    # create new tags iff post is valid
    if @post.valid? && @post.tag_ids.present?
      tags = @post.tag_ids.select { |id| id.to_i.zero? }.reject(&:blank?).compact.uniq
      @post.tag_ids -= tags
      @post.tag_ids += tags.map { |tag| Tag.create(user: current_user, name: tag).id }
    end

    if @post.save
      flash[:success] = "Your post has been updated."
      redirect_to post_path(@post)
    else
      flash.now[:error] = {}
      flash.now[:error][:array] = @post.errors.full_messages
      flash.now[:error][:message] = "Your post could not be saved because of the following problems:"
      @image = @post.icon
      @character = @post.character
      use_javascript('posts')
      build_template_groups
      build_tags
      render :action => :new
    end
  end

  def mark_unread
    @post.views.where(user_id: current_user.id).destroy_all
    flash[:success] = "Post has been marked as unread"
    redirect_to board_path(@post.board)
  end

  def change_status
    unless @post.metadata_editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this post."
      redirect_to post_path(@post)
    end

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

  def destroy
    @post.destroy
    flash[:success] = "Post deleted."
    redirect_to boards_path
  end

  def search
    return unless params[:commit].present?

    @search_results = Post.order('tagged_at desc').includes(:board)
    @search_results = @search_results.where(board_id: params[:board_id]) if params[:board_id].present?
    if params[:author_id].present?
      post_ids = Reply.where(user_id: params[:author_id]).select(:post_id).map(&:post_id).uniq
      where = Post.where(user_id: params[:author_id]).where(id: post_ids).where_values.reduce(:or)
      @search_results = @search_results.where(where)
    end
    if params[:character_id].present?
      post_ids = Reply.where(character_id: params[:character_id]).select(:post_id).map(&:post_id).uniq
      where = Post.where(character_id: params[:character_id]).where(id: post_ids).where_values.reduce(:or)
      @search_results = @search_results.where(where)
    end
    if params[:completed].present?
      @search_results = @search_results.where(status: Post::STATUS_COMPLETE)
    end

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

  def reorder_sections
    Post.transaction do
      params[:changes].each do |post_id, section_order|
        post = Post.where(id: post_id).first
        next unless post
        post.section_order = section_order
        post.save
      end
    end
    render json: {}
  end

  def build_tags
    @tags = Tag.all
    if @post.try(:tag_ids)
      new_tags = @post.tag_ids.reject { |t| t.blank? || !t.to_i.zero? }
      faked = Struct.new(:name, :id)
      @tags += new_tags.map { |t| faked.new(t, t) }
    end
  end
end
