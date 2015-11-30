class PostsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_post, :only => [:show, :edit, :update, :destroy]
  before_filter :build_template_groups, :only => [:new, :show, :edit, :preview]

  def index
    @posts = Post.order('updated_at desc').limit(25).includes(:board)
  end

  def new
    use_javascript('posts')
    @post = Post.new(character: current_user.active_character)
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
      @reply = Reply.new(post: @post, character: current_user.active_character, icon: current_user.active_character.try(:icon))
      @character = current_user.active_character
      @image = @character ? @character.icon : current_user.avatar
    end
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
    @rowspan = [per_page, @search_results.count].min + 1
    @rowspan += 1 if @search_results.count == 1 # pad for sizing
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
