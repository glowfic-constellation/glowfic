class Reply::Saver < Generic::Saver
  def initialize(model, user:, params:)
    @reply = model
    super
  end

  def create
    if reply.post.present?
      last_seen_reply_order = reply.post.last_seen_reply_for(@user).try(:reply_order)
      @unseen_replies = reply.post.replies.ordered.paginate(page: 1, per_page: 10)
      @unseen_replies = @unseen_replies.where('reply_order > ?', last_seen_reply_order) if last_seen_reply_order.present?
      most_recent_unseen_reply = @unseen_replies.last

      if @params[:allow_dupe].blank?
        last_by_user = reply.post.replies.where(user_id: reply.user_id).ordered.last
        match_attrs = ['content', 'icon_id', 'character_id', 'character_alias_id']
        if last_by_user.present? && last_by_user.attributes.slice(*match_attrs) == reply.attributes.slice(*match_attrs)
          @error_message = "This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional."
          @allow_dupe = true
          if @unseen_replies.count == 0 || (@unseen_replies.count == 1 && most_recent_unseen_reply.id == last_by_user.id)
            preview(reply)
          else
            draft = make_draft(false)
            preview(ReplyDraft.reply_from_draft(draft))
          end
          return
        end
      end

      if most_recent_unseen_reply.present?
        reply.post.mark_read(@user, reply.post.read_time_for(@unseen_replies))
        num = @unseen_replies.count
        pluraled = num > 1 ? "have been #{num} new replies" : "has been 1 new reply"
        @error_message = "There #{pluraled} since you last viewed this post."
        draft = make_draft
        preview(ReplyDraft.reply_from_draft(draft)) and return
      end
    end
    @reply.save
  end

  def update
    @reply.assign_attributes(permitted_params)
    preview(@reply) and return if @params[:button_preview]

    if @user.id != @reply.user_id && @reply.audit_comment.blank?
      @error_message = "You must provide a reason for your moderator edit."
      editor_setup
      render :edit and return
    end
    @reply.save
  end

  def permitted_params
    @params.fetch(:reply, {}).permit(
      :post_id,
      :content,
      :character_id,
      :icon_id,
      :audit_comment,
      :character_alias_id,
    )
  end
end
