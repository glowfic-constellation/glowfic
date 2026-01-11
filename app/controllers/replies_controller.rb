# frozen_string_literal: true
require 'will_paginate/array'

class RepliesController < WritableController
  before_action :login_required, except: [:search, :show, :history]
  before_action :get_multi_replies, only: [:create, :update]
  before_action :find_model, only: [:show, :history, :edit, :update, :destroy]
  before_action :editor_setup, only: [:edit]
  before_action :require_create_permission, only: [:create]
  before_action :require_edit_permission, only: [:edit, :update]

  def search
    @page_title = 'Search Replies'
    use_javascript('search')

    @post = Post.find_by(id: params[:post_id]) if params[:post_id].present?
    @icon = Icon.find_by(id: params[:icon_id]) if params[:icon_id].present?

    if @post&.visible_to?(current_user)
      gon.post_id = @post.id
    elsif @post
      # post exists but not visible
      @post = nil
      params[:commit] = nil
      flash.now[:error] = "You do not have permission to view this post."
    end

    searcher = Reply::Searcher.new(current_user: current_user, post: @post)
    searcher.setup(params)

    @users = searcher.users
    @characters = searcher.characters
    @templates = searcher.templates
    @boards = searcher.boards

    return unless params[:commit].present?

    response.headers['X-Robots-Tag'] = 'noindex'

    @search_results = searcher.search(params, page: page)
    @templates = searcher.templates
    @audits = []
    @reply_bookmarks = {}
  end

  def create
    if params[:button_preview]
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

    reply = Reply.new(permitted_params)
    reply.user = current_user
    process_npc(reply, permitted_character_params)

    if params[:button_add_more]
      # If they click "Add More", fetch the existing array of multi replies if present and add the current permitted_params to that list
      add_to_multi_reply(reply, permitted_params)
    elsif editing_multi_reply?
      edit_reply(true, new_multi_reply: reply)
    else
      post_replies(new_reply: reply)
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
    if params[:button_preview]
      preview_reply(@reply) and return
    elsif params[:button_add_more]
      # This will take us to reply create instead, but this reply's ID will be saved
      add_to_multi_reply(@reply, permitted_params) and return
    end

    if current_user.id != @reply.user_id && @reply.audit_comment.blank?
      flash[:error] = "You must provide a reason for your moderator edit."
      editor_setup
      render :edit and return
    end

    edit_reply(false)
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
    @reply = Reply.find_by(id: params[:id])

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

  def get_multi_replies
    # Get the multi replies stored in the page JSON
    @multi_replies_params = JSON.parse(params.fetch(:multi_replies_json, "[]")).map do |reply_json|
      permitted_params(ActionController::Parameters.new({ reply: reply_json }), [:id])
    end
    @multi_replies = @multi_replies_params.map do |reply_params|
      Reply.new(reply_params).tap { |r| r.user = current_user }
    end
  end

  def preview_reply(reply)
    # Previewing a specific reply
    @post = reply.post
    @reply = reply
    @reply.user = current_user unless @reply.user
    @audits = @reply.id.present? ? { @reply.id => @reply.audits.count } : {}
    @reply_bookmarks = {}
    @adding_to_multi_reply = false
    preview_replies
  end

  def add_to_multi_reply(reply, reply_params)
    # Adding a new reply to a multi reply
    post_id = params[:reply][:post_id]
    ReplyDraft.draft_for(post_id, current_user.id)&.destroy!

    # Save NPC
    if reply.character&.new_record?
      if reply.character.save
        flash[:success] = "Your new NPC has been persisted!"
        params[:reply][:character_id] = reply.character.id
        reply_params[:character_id] = reply.character.id
        reply.character_id = reply.character.id
      else
        flash[:error] = "There was a problem persisting your new NPC."
      end
    end

    # Add reply to list of multi replies
    reply.user = current_user unless reply.user
    @multi_replies << reply
    reply_params[:id] = reply.id if reply.id.present?
    @multi_replies_params << reply_params

    # Set up editor
    @post = reply.post
    empty_reply_hash = permitted_params.permit(:character_id, :character_alias_id)
    @reply = @post.build_new_reply_for(current_user, empty_reply_hash)
    @reply.assign_default_icon(current_user)
    @reply.editor_mode = reply.editor_mode
    @adding_to_multi_reply = true
    @audits = {}
    @reply_bookmarks = {}

    preview_replies
  end

  def preview_replies
    @page_title = @post.subject

    editor_setup
    render :preview
  end

  def post_replies(new_reply: nil)
    if new_reply.present?
      @multi_replies << new_reply
      @multi_replies_params << permitted_params
    end

    first_reply = @multi_replies.first
    replies_post = first_reply.post
    if replies_post.present?
      # Logic to check for reply duplication and unseen replies
      last_seen_reply_order = replies_post.last_seen_reply_for(current_user).try(:reply_order)
      @unseen_replies = replies_post.replies.ordered.paginate(page: 1, per_page: 10)
      if last_seen_reply_order.present?
        @unseen_replies = @unseen_replies.where('reply_order > ?', last_seen_reply_order)
        @audits = Audited::Audit.where(auditable_id: @unseen_replies.map(&:id)).group(:auditable_id).count
      end
      most_recent_unseen_reply = @unseen_replies.last

      if params[:allow_dupe].blank?
        # Confirm that the user really wants the first of their new replies to match the latest reply on the thread
        last_by_user = replies_post.replies.where(user_id: first_reply.user_id).ordered.last
        match_attrs = ['content', 'icon_id', 'character_id', 'character_alias_id']
        if last_by_user.present? && last_by_user.attributes.slice(*match_attrs) == first_reply.attributes.slice(*match_attrs)
          flash.now[:error] = "This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional."
          @allow_dupe = true
          if most_recent_unseen_reply.nil? || (most_recent_unseen_reply.id == last_by_user.id && @unseen_replies.one?)
            preview_reply(first_reply)
          else
            draft = make_draft(false)
            preview_reply(ReplyDraft.reply_from_draft(draft))
          end
          return
        end
      end

      if most_recent_unseen_reply.present?
        # Show a list of unseen replies before posting a new one
        replies_post.mark_read(current_user, at_time: replies_post.read_time_for(@unseen_replies))
        num = @unseen_replies.count
        pluraled = num > 1 ? "have been #{num} new replies" : "has been 1 new reply"
        flash.now[:error] = "There #{pluraled} since you last viewed this post."

        # special handling for multi reply to keep the latest reply out of the preview list
        if @multi_replies.size > 1
          @multi_replies.delete(new_reply)
          @multi_replies_params.delete(permitted_params)
        end

        draft = make_draft
        preview_reply(ReplyDraft.reply_from_draft(draft)) and return
      end
    end

    begin
      Reply.transaction { @multi_replies.each(&:save!) }
    rescue ActiveRecord::RecordInvalid => e
      errored_reply = @multi_replies.detect { |r| r.errors.present? } || first_reply
      render_errors(errored_reply, action: 'created', now: true, err: e)

      redirect_to posts_path and return unless errored_reply.post
      redirect_to post_path(errored_reply.post) and return
    end

    flash[:success] = "#{'Reply'.pluralize(@multi_replies.length)} posted."
    redirect_to reply_path(first_reply, anchor: "reply-#{first_reply.id}")
  end

  def editing_multi_reply?
    # If the list of params is present and the first item on the list has the ID stored, I am editing it
    # @reply isn't set correctly at this point so I update it to be the reply found by the first multi-reply element's ID
    @multi_replies_params.present? && (@reply = Reply.find_by(id: @multi_replies_params.first["id"]))
  end

  def edit_reply(editing_multi_reply, new_multi_reply: nil)
    begin
      Reply.transaction do
        edit_multi_replies(new_multi_reply) if editing_multi_reply

        @reply.save!
      end
    rescue ActiveRecord::RecordInvalid => e
      if @multi_replies.blank?
        render_errors(@reply, action: 'updated', now: true, err: e)
      else
        errored_reply = @multi_replies.detect { |r| r.errors.present? } || @reply
        render_errors(errored_reply, action: 'updated', now: true, err: e)
      end

      @post ||= @reply.post
      @audits = { @reply.id => @post.audits.count }
      @reply_bookmarks = {}
      editor_setup
      render :edit
    else
      flash[:success] = "Reply updated."
      redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
    end
  end

  def edit_multi_replies(new_multi_reply)
    # Add new replies after the one being edited and before the next
    if new_multi_reply.present?
      # Including the reply in the text editor, not just the ones in the JSON
      @multi_replies << new_multi_reply
      @multi_replies_params << permitted_params
    end
    reply_contents = @reply.dup

    # Modify the original reply with the parameters of the first reply in the JSON
    @reply.assign_attributes(@multi_replies_params.shift)
    @multi_replies.shift

    # Check whether there are any further replies beyond the very first one
    num_new_replies = @multi_replies_params.length
    return if num_new_replies == 0

    # Reorder the replies after this one
    original_order = @reply.order
    following_replies = @reply.post.replies.where("reply_order > ?", original_order)
    following_replies.update_all(["reply_order = reply_order + ?", num_new_replies]) # rubocop:disable Rails/SkipsModelValidations

    # Create the new replies
    @multi_replies_params.each_with_index do |reply_params, idx|
      # Create a fake temporary reply with the contents of the original one to be in history
      @multi_replies[idx] = new_reply = reply_contents.dup
      new_reply.order = original_order + idx + 1
      new_reply.created_at = @reply.created_at
      new_reply.skip_post_update = true
      new_reply.is_import = true
      new_reply.skip_notify = true
      new_reply.save!

      # Update the new reply added with the actual params that should be there
      new_reply.update!(reply_params)
    end
  end
end
