# frozen_string_literal: true
class RepliesController < WritableController
  before_filter :login_required, except: [:show, :history]
  before_filter :find_reply, only: [:show, :history, :edit, :update, :destroy]
  before_filter :build_template_groups, only: [:edit]
  before_filter :require_permission, only: [:edit, :update, :destroy]

  def create
    gon.original_content = params[:reply].try(:[], :content)

    if params[:button_preview]
      @url = replies_path
      @method = :post
      preview
      render :action => 'preview' and return
    end

    if params[:button_draft]
      if draft = ReplyDraft.draft_for(params[:reply][:post_id], current_user.id)
        draft.assign_attributes(params[:reply])
      else
        draft = ReplyDraft.new(params[:reply])
        draft.user = current_user
      end

      if draft.save
        flash[:success] = "Draft saved!"
      else
        flash[:error] = {}
        flash[:error][:message] = "Your draft could not be saved because of the following problems:"
        flash[:error][:array] = draft.errors.full_messages
      end
      redirect_to post_path(draft.post, page: :last) and return
    end


    reply = Reply.new(params[:reply])
    reply.user = current_user
    if reply.save
      flash[:success] = "Posted!"
      redirect_to reply_path(reply, anchor: "reply-#{reply.id}")
    else
      flash[:error] = {}
      flash[:error][:message] = "Your post could not be saved because of the following problems:"
      flash[:error][:array] = reply.errors.full_messages
      redirect_to posts_path and return unless reply.post
      redirect_to post_path(reply.post)
    end
  end

  def show
    @page_title = @post.subject
    params[:page] ||= @reply.post_page(per_page)

    show_post(params[:page])
  end

  def history
  end

  def edit
    use_javascript('posts')
    gon.original_content = @reply.content
  end

  def update
    gon.original_content = params[:reply][:content]
    if params[:button_preview]
      @url = reply_path(params[:id])
      @method = :put
      preview
      render :action => 'preview'
    else
      @reply.skip_post_update = true unless @reply.post.last_reply_id == @reply.id
      @reply.update_attributes(params[:reply])
      flash[:success] = "Post updated"
      redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
    end
  end

  def destroy
    to_page = @reply.post_page(per_page) # get index before destroying
    @reply.destroy # to destroy subsequent ones, do @reply.destroy_subsequent_replies
    flash[:success] = "Post deleted."
    redirect_to post_path(@reply.post, page: to_page)
  end

  private

  def find_reply
    @reply = Reply.find_by_id(params[:id])

    unless @reply
      flash[:error] = "Post could not be found."
      redirect_to boards_path and return
    end

    @post = @reply.post
    unless @post.visible_to?(current_user)
      flash[:error] = "You do not have permission to view this post."
      redirect_to boards_path and return
    end

    @page_title = @post.subject
  end

  def require_permission
    unless @reply.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this post."
      redirect_to post_path(@reply.post)
    end
  end

  def preview
    build_template_groups

    @written = Reply.new(params[:reply])
    @post = @written.post
    @written.user = current_user

    @page_title = @post.subject

    use_javascript('posts')
  end
end
