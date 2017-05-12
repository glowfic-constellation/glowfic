# frozen_string_literal: true
class RepliesController < WritableController
  before_filter :login_required, except: [:search, :show, :history]
  before_filter :find_reply, only: [:show, :history, :edit, :update, :destroy]
  before_filter :build_template_groups, only: [:edit]
  before_filter :require_permission, only: [:edit, :update, :destroy]

  def search
    @page_title = 'Search Replies'

    @post = Post.find_by_id(params[:post_id]) if params[:post_id].present?
    if @post.try(:visible_to?, current_user)
      @users = @post.authors
      char_ids = @post.replies.pluck('distinct character_id') + [@post.character_id]
      @characters = Character.where(id: char_ids).order('name')
      @templates = Template.where(id: @characters.map(&:template_id).uniq.compact).order('name')
    else
      @users = User.order('username')
      @characters = Character.order('name')
      @templates = Template.order('name')
      if @post
        # post exists but post not visible
        flash[:error] = "You do not have permission to view this post."
        return
      end
    end

    return unless params[:commit].present?

    @search_results = Reply.unscoped
    @search_results = @search_results.where(user_id: params[:author_id]) if params[:author_id].present?
    @search_results = @search_results.where(character_id: params[:character_id]) if params[:character_id].present?
    @search_results = @search_results.where(icon_id: params[:icon_id]) if params[:icon_id].present?

    if params[:subj_content].present?
      @search_results = @search_results.search(params[:subj_content]).with_pg_search_highlight
      exact_phrases = params[:subj_content].scan(/"([^"]*)"/)
      if exact_phrases.present?
        exact_phrases.each do |phrase|
          phrase = phrase.first.strip
          next if phrase.blank?
          @search_results = @search_results.where("replies.content LIKE ?", "%#{phrase}%")
        end
      end
    else
      @search_results = @search_results.order('replies.id DESC')
    end

    if @post
      @search_results = @search_results.where(post_id: @post.id)
    elsif params[:board_id].present?
      post_ids = Post.where(board_id: params[:board_id]).pluck(:id)
      @search_results = @search_results.where(post_id: post_ids)
    end

    if params[:template_id].present?
      template = Template.find_by_id(params[:template_id])
      if template.present?
        character_ids = Character.where(template_id: template.id).pluck(:id)
        @search_results = @search_results.where(character_id: character_ids)
      end
    end

    @search_results = @search_results
      .select('replies.*, characters.name, characters.screenname, users.username, posts.subject')
      .joins(:user, :post)
      .joins("LEFT OUTER JOIN characters ON characters.id = replies.character_id")
      .paginate(page: page, per_page: 25)
    if @search_results.total_pages <= 1
      @search_results = @search_results.select {|reply| reply.post.visible_to?(current_user)}.paginate(page: page, per_page: 25)
    end
  end

  def make_draft
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
    draft
  end

  def create
    if params[:button_draft]
      draft = make_draft
      redirect_to post_path(draft.post, page: :unread, anchor: :unread) and return # TODO handle draft.post.nil?
    elsif params[:button_preview]
      draft = make_draft
      preview(ReplyDraft.reply_from_draft(draft)) and return
    end

    reply = Reply.new(params[:reply])
    reply.user = current_user

    if reply.post.present?
      last_seen_reply_id = params[:last_seen]
      @unseen_replies = reply.post.replies.order('id asc').paginate(page: 1, per_page: 5)
      @unseen_replies = @unseen_replies.where('id > ?', last_seen_reply_id) if last_seen_reply_id.present?
      most_recent_unseen_reply = @unseen_replies.last
      if most_recent_unseen_reply.present?
        flash[:error] = "There have been #{@unseen_replies.count} new replies since you last viewed this post."
        @last_seen_id = most_recent_unseen_reply.id
        preview(reply) and return
      end
    end

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
  end

  def update
    @reply.assign_attributes(params[:reply])
    preview(@reply) and return if params[:button_preview]

    @reply.skip_post_update = true unless @reply.post.last_reply_id == @reply.id
    @reply.save
    flash[:success] = "Post updated"
    redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
  end

  def destroy
    previous_reply = @reply.send(:previous_reply)
    to_page = previous_reply.try(:post_page, per_page) || 1
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

  def preview(written)
    build_template_groups

    @written = written
    @post = @written.post
    @written.user = current_user

    @page_title = @post.subject

    use_javascript('posts')
    render :action => :preview
  end
end
