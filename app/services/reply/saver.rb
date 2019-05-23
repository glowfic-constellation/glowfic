class Reply::Saver < Auditable::Saver
  def initialize(reply, user:, params:)
    @reply = reply
    super
  end

  def create!
    build

    if @reply.post.present?
      last_seen_reply_order = @reply.post.last_seen_reply_for(@user).try(:reply_order)
      @unseen_replies = @reply.post.replies.ordered.paginate(page: 1, per_page: 10)
      @unseen_replies = @unseen_replies.where('reply_order > ?', last_seen_reply_order) if last_seen_reply_order.present?
      if @unseen_replies.present?
        @reply.post.mark_read(@user, @reply.post.read_time_for(@unseen_replies))
        num = @unseen_replies.count
        raise UnseenRepliesError, "There #{'has'.pluralize(num)} been #{num} new #{'reply'.pluralize(num)} since you last viewed this post."
      end

      if @reply.user_id.present? && @params[:allow_dupe].blank?
        last_by_user = @reply.post.replies.where(user_id: @reply.user_id).ordered.last
        match_attrs = ['content', 'icon_id', 'character_id', 'character_alias_id']
        raise DuplicateReplyError if last_by_user.present? && last_by_user.attributes.slice(*match_attrs) == @reply.attributes.slice(*match_attrs)
      end
    end

    save!
  end

  private

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

class UnseenRepliesError < ApiError
end

class DuplicateReplyError < ApiError
  def initialize(msg="This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional.")
    super(msg)
  end
end
