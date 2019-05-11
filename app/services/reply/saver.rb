class Reply::Saver < Generic::Saver
  def initialize(reply, user:, params:)
    @reply = reply
    @user = user
    @params = params
  end

  def create
    if reply.post.present?
      last_seen_reply_order = reply.post.last_seen_reply_for(current_user).try(:reply_order)
      @unseen_replies = reply.post.replies.ordered.paginate(page: 1, per_page: 10)
      @unseen_replies = @unseen_replies.where('reply_order > ?', last_seen_reply_order) if last_seen_reply_order.present?
      most_recent_unseen_reply = @unseen_replies.last
      if most_recent_unseen_reply.present?
        reply.post.mark_read(current_user, reply.post.read_time_for(@unseen_replies))
        num = @unseen_replies.count
        pluraled = num > 1 ? "have been #{num} new replies" : "has been 1 new reply"
        flash.now[:error] = "There #{pluraled} since you last viewed this post."
        draft = make_draft
        preview(ReplyDraft.reply_from_draft(draft)) and return
      end

      if reply.user_id.present? && params[:allow_dupe].blank?
        last_by_user = reply.post.replies.where(user_id: reply.user_id).ordered.last
        if last_by_user.present?
          match_attrs = ['content', 'icon_id', 'character_id', 'character_alias_id']
          if last_by_user.attributes.slice(*match_attrs) == reply.attributes.slice(*match_attrs)
            flash.now[:error] = "This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional."
            @allow_dupe = true
            draft = make_draft(false)
            preview(ReplyDraft.reply_from_draft(draft)) and return
          end
        end
      end
    end

    if reply.save
      flash[:success] = "Posted!"
      redirect_to reply_path(reply, anchor: "reply-#{reply.id}")
    else
      flash[:error] = {}
      flash[:error][:message] = "Your reply could not be saved because of the following problems:"
      flash[:error][:array] = reply.errors.full_messages
      redirect_to posts_path and return unless reply.post
      redirect_to post_path(reply.post)
    end
  end

  def update
    @reply.assign_attributes(reply_params)
    preview(@reply) and return if params[:button_preview]

    if current_user.id != @reply.user_id && @reply.audit_comment.blank?
      flash[:error] = "You must provide a reason for your moderator edit."
      editor_setup
      render :edit and return
    end

    @reply.audit_comment = nil if @reply.changes.empty? # don't save an audit for a note and no changes
    unless @reply.save
      flash[:error] = {}
      flash[:error][:message] = "Your reply could not be saved because of the following problems:"
      flash[:error][:array] = @reply.errors.full_messages
      editor_setup
      render :edit and return
    end

    flash[:success] = "Post updated"
    redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
  end

  def reply_params
    params.fetch(:reply, {}).permit(
      :post_id,
      :content,
      :character_id,
      :icon_id,
      :audit_comment,
      :character_alias_id,
    )
  end
end
