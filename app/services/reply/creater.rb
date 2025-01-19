# frozen_string_literal: true
class Reply::Creater < Object
  attr_reader :reply, :unseen_replies, :audits, :allow_dupe

  def initialize(params, user:, char_params: {})
    @reply = Reply.new(params)
    reply.user = user
    process_npc(@reply, char_params)
  end

  def check(params)
    return :no_post unless @reply.post.present?

    post = @reply.post

    last_seen_reply_order = post.last_seen_reply_for(current_user).try(:reply_order)
    @unseen_replies = post.replies.ordered.paginate(page: 1, per_page: 10)

    if last_seen_reply_order.present?
      @unseen_replies = @unseen_replies.where('reply_order > ?', last_seen_reply_order)
      @audits = Audited::Audit.where(auditable_id: @unseen_replies.map(&:id)).group(:auditable_id).count
    end

    most_recent_unseen_reply = @unseen_replies.last

    if params[:allow_dupe].blank?
      last_by_user = post.replies.where(user: @reply.user).ordered.last
      match_attrs = ['content', 'icon_id', 'character_id', 'character_alias_id']

      if last_by_user.present? && last_by_user.attributes.slice(*match_attrs) == @reply.attributes.slice(*match_attrs)
        flash.now[:error] = "This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional."
        @allow_dupe = true

        if most_recent_unseen_reply.nil? || (most_recent_unseen_reply.id == last_by_user.id && @unseen_replies.count == 1)
          preview_reply(@reply)
        else
          draft = make_draft(false)
          preview_reply(ReplyDraft.reply_from_draft(draft))
        end

        return :duplicate
      end
    end

    return :clear unless most_recent_unseen_reply.present?

    post.mark_read(current_user, at_time: post.read_time_for(@unseen_replies))

    num = @unseen_replies.count
    pluraled = "#{'has'.pluralize(num)} been #{num} new #{'reply'.pluralize(num)}"
    flash.now[:error] = "There #{pluraled} since you last viewed this post."

    draft = make_draft
    preview_reply(ReplyDraft.reply_from_draft(draft))
    :unseen
  end
end
