# frozen_string_literal: true
class Reply::Creater < Object
  attr_reader :reply, :unseen_replies, :audits, draft

  def initialize(params, user:, char_params: {}, multi_reply: false)
    @reply = Reply.new(params)
    @reply.user = user
    @reply = Character::NpcCreator.new(@reply, user: user, char_params: char_params).process
    @params = params
    @multi_reply = multi_reply
  end

  def check_buttons
    if params[:button_draft]
      @draft = make_draft
      :draft
    elsif params[:button_delete_draft]
      post_id = params[:reply][:post_id]
      @draft = ReplyDraft.draft_for(post_id, current_user.id)
      @draft&.destroy ? :draft_destroy_success : :draft_destroy_failure
    elsif params[:button_preview]
      @draft = make_draft
      :preview
    elsif params[:button_submit_previewed_multi_reply]
      editing_multi_reply? ? :edit_multi_reply : :create_multi_reply
    elsif params[:button_discard_multi_reply]
      :discard_multi_reply
    else
      :none
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

    @draft = make_draft(false)
    preview_reply(ReplyDraft.reply_from_draft(draft))
    :unseen
  end

  private

  def make_draft(message=true)
    Reply::Drafter.new(@params, user: @reply.user).make_draft(message)
  end

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

  def editing_multi_reply?
    # If the list of params is present and the first item on the list has the ID stored, I am editing it
    @multi_replies_params.present? && (@reply = Reply.find_by(id: @multi_replies_params.first["id"]))
  end
end
