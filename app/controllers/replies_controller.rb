class RepliesController < WritableController
  before_filter :login_required, except: [:show, :history]
  before_filter :build_template_groups, only: [:show, :edit]
  before_filter :find_reply, only: [:show, :history, :edit, :update, :destroy]
  before_filter :require_permission, only: [:edit, :update, :destroy]

  def create
    if params[:button_preview]
      @url = replies_path
      @method = :post
      preview
      render :action => 'preview'
    else
      reply = Reply.new(params[:reply])
      reply.user = current_user
      if reply.save
        flash[:success] = "Posted!"
        redirect_to reply_path(reply, anchor: "reply-#{reply.id}")
      else
        flash[:error] = "Problems. "+reply.errors.full_messages.to_s
        redirect_to post_path(reply.post)
      end
    end
  end
  
  def preview
    build_template_groups
    
    @written = Reply.new(params[:reply])
    @post = @written.post
    @written.user = current_user

    use_javascript('posts')
  end

  def show
    @post = @reply.post
    current_page = params[:page] || @reply.post_page(per_page)
    show_post(current_page)
  end

  def history
  end

  def edit
    @character = @reply.character
    @image = @reply.icon
    use_javascript('posts')
  end

  def update
    if params[:button_preview]
      @url = reply_path(params[:id])
      @method = :put
      preview
      render :action => 'preview'
    else
      @reply.update_attributes(params[:reply])
      flash[:success] = "Post updated"
      redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
    end
  end

  def destroy
    @reply.destroy
    flash[:success] = "Post deleted."
    redirect_to post_path(@reply.post)
  end

  private

  def find_reply
    @reply = Reply.find_by_id(params[:id])

    unless @reply
      flash[:error] = "Post could not be found."
      redirect_to boards_path and return
    end
  end

  def require_permission
    unless @reply.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this post."
      redirect_to post_path(@reply.post)
    end
  end
end
