# frozen_string_literal: true
class Reply::Creater < Object
  attr_reader :reply, :unseen_replies, :audits

  def initialize(params, user:, char_params: {})
    @reply = Reply.new(params)
    @reply.user = user
    @reply = Character::NpcCreator.new(@reply, user: user, char_params: char_params).process
    @params = params
  end

  def check_buttons
    if params[:button_draft]
      draft = make_draft
      redirect_to posts_path and return unless draft.post
      redirect_to post_path(draft.post, page: :unread, anchor: :unread) and return
    elsif params[:button_delete_draft]
      post_id = params[:reply][:post_id]
      draft = ReplyDraft.draft_for(post_id, current_user.id)
      if draft&.destroy
        flash[:success] = "Draft deleted."
      else
        flash[:error] = {
          message: "Draft could not be deleted",
          array: draft&.errors&.full_messages,
        }
      end
      redirect_to post_path(post_id, page: :unread, anchor: :unread) and return
    elsif params[:button_preview]
      draft = make_draft
      preview_reply(ReplyDraft.reply_from_draft(draft)) and return
    elsif params[:button_submit_previewed_multi_reply]
      if editing_multi_reply?
        edit_reply(true)
      else
        post_replies
      end
      return
    elsif params[:button_discard_multi_reply]
      flash[:success] = "Replies discarded."
      if editing_multi_reply?
        # Editing multi reply, going to redirect back to the reply I'm editing
        redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
      else
        # Posting a new multi reply, go back to unread
        redirect_to post_path(params[:reply][:post_id], page: :unread, anchor: :unread)
      end
      return
    end
  end

  def check_status
    return :no_post unless @reply.post.present?

    post = @reply.post

    last_seen_reply_order = post.last_seen_reply_for(current_user).try(:reply_order)
    @unseen_replies = post.replies.ordered.paginate(page: 1, per_page: 10)

    if last_seen_reply_order.present?
      @unseen_replies = @unseen_replies.where('reply_order > ?', last_seen_reply_order)
      @audits = Audited::Audit.where(auditable_id: @unseen_replies.map(&:id)).group(:auditable_id).count
    end

    most_recent_unseen_reply = @unseen_replies.last

    return :duplicate if @params[:allow_dupe].blank? && check_dupe
    return :clear unless most_recent_unseen_reply.present?

    post.mark_read(current_user, at_time: post.read_time_for(@unseen_replies))

    draft = Reply::Drafter.new(@params, user: user).make_draft(false)
    preview_reply(ReplyDraft.reply_from_draft(draft))
    :unseen
  end

  private

  def check_dupe
    last_by_user = post.replies.where(user: @reply.user).ordered.last
    match_attrs = ['content', 'icon_id', 'character_id', 'character_alias_id']

    return false unless last_by_user.present? && last_by_user.attributes.slice(*match_attrs) == @reply.attributes.slice(*match_attrs)

    if most_recent_unseen_reply.nil? || (most_recent_unseen_reply.id == last_by_user.id && @unseen_replies.count == 1)
      preview_reply(@reply)
    else
      draft = Reply::Drafter.new(@params, user: user).make_draft(false)
      preview_reply(ReplyDraft.reply_from_draft(draft))
    end

    true
  end
end
