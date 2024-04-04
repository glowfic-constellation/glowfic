# frozen_string_literal: true
require 'will_paginate/array'

class RepliesController < WritableController
  before_action :login_required, except: [:search, :show, :history]
  before_action :find_model, only: [:show, :history, :edit, :update, :destroy]
  before_action :editor_setup, only: [:edit]
  before_action :require_create_permission, only: [:create]
  before_action :require_edit_permission, only: [:edit, :update]

  def search
    @page_title = 'Search Replies'
    use_javascript('posts/search')

    @post = Post.find_by_id(params[:post_id]) if params[:post_id].present?
    @icon = Icon.find_by_id(params[:icon_id]) if params[:icon_id].present?
    if @post.try(:visible_to?, current_user)
      @users = @post.authors.active
      char_ids = @post.replies.select(:character_id).distinct.pluck(:character_id) + [@post.character_id]
      @characters = Character.where(id: char_ids).ordered
      @templates = Template.where(id: @characters.map(&:template_id).uniq.compact).ordered
      gon.post_id = @post.id
    else
      @users = User.active.where(id: params[:author_id]) if params[:author_id].present?
      @characters = Character.where(id: params[:character_id]) if params[:character_id].present?
      @templates = Template.ordered.limit(25)
      @boards = Board.where(id: params[:board_id]) if params[:board_id].present?
      if @post
        # post exists but post not visible
        flash.now[:error] = "You do not have permission to view this post."
        return
      end
    end

    return unless params[:commit].present?

    searcher = Reply::Searcher.new(templates: @templates, users: @users)
    @search_results = searcher.search(params, post: @post, page: page)
    @audits = []
    @search_results = @search_results.visible_to(current_user)
    @templates = searcher.templates
    @users = searcher.users
  end

  def create
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
      preview(ReplyDraft.reply_from_draft(draft)) and return
    end

    reply = Reply.new(permitted_params)
    reply.user = current_user
    process_npc(reply, permitted_character_params)

    if reply.post.present?
      last_seen_reply_order = reply.post.last_seen_reply_for(current_user).try(:reply_order)
      @unseen_replies = reply.post.replies.ordered.paginate(page: 1, per_page: 10)
      if last_seen_reply_order.present?
        @unseen_replies = @unseen_replies.where('reply_order > ?', last_seen_reply_order)
        @audits = Audited::Audit.where(auditable_id: @unseen_replies.map(&:id)).group(:auditable_id).count
      end
      most_recent_unseen_reply = @unseen_replies.last

      if params[:allow_dupe].blank?
        last_by_user = reply.post.replies.where(user_id: reply.user_id).ordered.last
        match_attrs = ['content', 'icon_id', 'character_id', 'character_alias_id']
        if last_by_user.present? && last_by_user.attributes.slice(*match_attrs) == reply.attributes.slice(*match_attrs)
          flash.now[:error] = "This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional."
          @allow_dupe = true
          if most_recent_unseen_reply.nil? || (most_recent_unseen_reply.id == last_by_user.id && @unseen_replies.count == 1)
            preview(reply)
          else
            draft = make_draft(false)
            preview(ReplyDraft.reply_from_draft(draft))
          end
          return
        end
      end

      if most_recent_unseen_reply.present?
        reply.post.mark_read(current_user, at_time: reply.post.read_time_for(@unseen_replies))
        num = @unseen_replies.count
        pluraled = num > 1 ? "have been #{num} new replies" : "has been 1 new reply"
        flash.now[:error] = "There #{pluraled} since you last viewed this post."
        draft = make_draft
        preview(ReplyDraft.reply_from_draft(draft)) and return
      end
    end

    begin
      reply.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(reply, action: 'created', now: true, err: e)

      redirect_to posts_path and return unless reply.post
      redirect_to post_path(reply.post)
    else
      flash[:success] = "Reply posted."
      redirect_to reply_path(reply, anchor: "reply-#{reply.id}")
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
  end

  def update
    @reply.assign_attributes(permitted_params)
    process_npc(@reply, permitted_character_params)
    preview(@reply) and return if params[:button_preview]

    if current_user.id != @reply.user_id && @reply.audit_comment.blank?
      flash[:error] = "You must provide a reason for your moderator edit."
      editor_setup
      render :edit and return
    end

    begin
      @reply.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(@reply, action: 'updated', now: true, err: e)

      @audits = { @reply.id => @post.audits.count }
      editor_setup
      render :edit
    else
      flash[:success] = "Reply updated."
      redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
    end
  end

  def destroy
    unless @reply.deletable_by?(current_user)
      flash[:error] = "You do not have permission to modify this reply."
      redirect_to post_path(@reply.post) and return
    end

    previous_reply = @reply.send(:previous_reply)
    to_page = previous_reply.try(:post_page, per_page) || 1

    # to destroy subsequent replies, do @reply.destroy_subsequent_replies
    begin
      @reply.destroy!
    rescue ActiveRecord::RecordNotDestroyed => e
      render_errors(@reply, action: 'deleted', err: e)
      redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
    else
      flash[:success] = "Reply deleted."
      redirect_to post_path(@reply.post, page: to_page)
    end
  end

  def restore
    audit = Audited::Audit.where(action: 'destroy').order(id: :desc).find_by(auditable_id: params[:id])
    unless audit
      flash[:error] = "Reply could not be found."
      redirect_to continuities_path and return
    end

    if audit.auditable
      flash[:error] = "Reply does not need restoring."
      redirect_to post_path(audit.associated) and return
    end

    new_reply = Reply.new(audit.audited_changes)
    new_reply.created_at = Audited::Audit.order(id: :asc).find_by(action: 'create', auditable_id: params[:id]).created_at
    unless new_reply.editable_by?(current_user)
      flash[:error] = "You do not have permission to modify this reply."
      redirect_to post_path(new_reply.post) and return
    end

    new_reply.is_import = true
    new_reply.skip_notify = true
    new_reply.id = audit.auditable_id

    following_replies = new_reply.post.replies.where('id > ?', new_reply.id).order(id: :asc)
    new_reply.skip_post_update = following_replies.exists?
    new_reply.reply_order = following_replies.first&.reply_order

    Reply.transaction do
      following_replies.update_all('reply_order = reply_order + 1') # rubocop:disable Rails/SkipsModelValidations
      new_reply.save!
    end

    flash[:success] = "Reply restored."
    redirect_to reply_path(new_reply)
  end

  private

  def find_model
    @reply = Reply.find_by_id(params[:id])

    unless @reply
      flash[:error] = "Post could not be found."
      redirect_to continuities_path and return
    end

    @post = @reply.post
    unless @post.visible_to?(current_user)
      flash[:error] = "You do not have permission to view this post."
      redirect_to continuities_path and return
    end

    @page_title = @post.subject
  end

  def require_create_permission
    return unless current_user.read_only?
    flash[:error] = "You do not have permission to create replies."
    redirect_to continuities_path and return
  end

  def require_edit_permission
    return if @reply.editable_by?(current_user)
    flash[:error] = "You do not have permission to modify this reply."
    redirect_to post_path(@reply.post)
  end

  def preview(written)
    @written = written
    @post = @written.post
    @written.user = current_user unless @written.user
    @audits = @written.id.present? ? { @written.id => @written.audits.count } : {}

    @page_title = @post.subject

    editor_setup
    render :preview
  end

  def make_draft(show_message=true)
    if (draft = ReplyDraft.draft_for(params[:reply][:post_id], current_user.id))
      draft.assign_attributes(permitted_params)
    else
      draft = ReplyDraft.new(permitted_params)
      draft.user = current_user
    end
    process_npc(draft, permitted_character_params)
    new_npc = !draft.character.nil? && !draft.character.persisted?

    begin
      draft.save!
    rescue ActiveRecord::RecordInvalid => e
      render_errors(draft, action: 'saved', class_name: 'Draft', err: e)
    else
      if show_message
        msg = "Draft saved."
        msg += " Your new NPC character has also been persisted!" if new_npc
        flash[:success] = msg
      end
    end
    draft
  end
end
