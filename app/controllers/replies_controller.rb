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

    @post = Post.find_by_id(params[:post_id]) if params[:post_id].present?
    @icon = Icon.find_by_id(params[:icon_id]) if params[:icon_id].present?
    if @post.try(:visible_to?, current_user)
      @users = @post.authors.active
      char_ids = @post.replies.select(:character_id).distinct.pluck(:character_id) + [@post.character_id]
      @characters = Character.where(id: char_ids).ordered
      @templates = Template.where(id: @characters.map(&:template_id).uniq.compact).ordered
      gon.post_id = @post.id
    else
      @users = User.active.full.where(id: params[:author_id]) if params[:author_id].present?
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

    response.headers['X-Robots-Tag'] = 'noindex'
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
          @search_results = @search_results.where("replies.content ILIKE ?", "%#{phrase}%")
        end
      end
    end

    append_rank = params[:subj_content].present? ? ', rank DESC' : ''
    if params[:sort] == 'created_new'
      @search_results = @search_results.except(:order).order('replies.created_at DESC' + append_rank)
    elsif params[:sort] == 'created_old'
      @search_results = @search_results.except(:order).order('replies.created_at ASC' + append_rank)
    elsif params[:subj_content].blank?
      @search_results = @search_results.order('replies.created_at DESC')
    end

    if @post
      @search_results = @search_results.where(post_id: @post.id)
    elsif params[:board_id].present?
      post_ids = Post.where(board_id: params[:board_id]).pluck(:id)
      @search_results = @search_results.where(post_id: post_ids)
    end

    if params[:template_id].present?
      @templates = Template.where(id: params[:template_id])
      if @templates.first.present?
        character_ids = Character.where(template_id: @templates.first.id).pluck(:id)
        @search_results = @search_results.where(character_id: character_ids)
      end
    elsif params[:author_id].present?
      @templates = @templates.where(user_id: params[:author_id])
    end

    @search_results = @search_results
      .select('replies.*, characters.name, characters.screenname, users.username, users.deleted as user_deleted')
      .visible_to(current_user)
      .joins(:user)
      .left_outer_joins(:character)
      .paginate(page: page)
      .includes(:post)

    @search_results = @search_results.where.not(post_id: current_user.hidden_posts) if logged_in? && !params[:show_blocked]

    @audits = []

    return if params[:condensed]

    @search_results = @search_results
      .select('icons.keyword, icons.url')
      .left_outer_joins(:icon)
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
      preview_reply(ReplyDraft.reply_from_draft(draft)) and return
    elsif params[:button_submit_previewed_multi_reply]
      post_replies
      return
    elsif params[:button_discard_multi_reply]
      flash[:success] = "Replies discarded."
      if @multi_replies_json.present? && (editing_reply_id = @multi_replies_json.first["id"]).present?
        # Editing multi reply, going to redirect back to the reply I'm editing
        redirect_to reply_path(editing_reply_id, anchor: "reply-#{editing_reply_id}") and return
      else
        # Posting a new multi reply, go back to unread
        redirect_to post_path(params[:reply][:post_id], page: :unread, anchor: :unread) and return
      end
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
            preview_reply(reply)
          else
            draft = make_draft(false)
            preview_reply(ReplyDraft.reply_from_draft(draft))
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
        preview_reply(ReplyDraft.reply_from_draft(draft)) and return
      end
    end

    if params[:button_add_more]
      # If they click "Add More", fetch the existing array of multi replies if present and add the current permitted_params to that list
      add_to_multi_reply(reply, permitted_params)
      return
    end

    post_replies(new_reply: reply)
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

    edit_reply
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

  def get_multi_replies
    @multi_replies_json = JSON.parse(params.fetch(:multi_replies_json, "[]"))
    @multi_replies = @multi_replies_json.map do |reply_json|
      Reply.new(permitted_params(ActionController::Parameters.new({ reply: reply_json })))
        .tap { |r| r.user = current_user }
    end
  end

  def preview_reply(reply)
    preview_replies(reply_to_preview: reply)
  end

  def add_to_multi_reply(reply, reply_params)
    post_id = params[:reply][:post_id]
    ReplyDraft.draft_for(post_id, current_user.id).try(:destroy)

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

    preview_replies(multi_reply_to_add: reply, multi_reply_params: reply_params)
  end

  def preview_replies(reply_to_preview: nil, multi_reply_to_add: nil, multi_reply_params: nil)
    if reply_to_preview
      # Previewing a specific reply
      @post = reply_to_preview.post
      @written = reply_to_preview
      @written.user = current_user unless @written.user
      @audits = @written.id.present? ? { @written.id => @written.audits.count } : {}
      @reply = @written # So that editor_setup shows the correct characters
    else
      # Adding a new reply to a multi reply
      @post = multi_reply_to_add.post
      empty_reply_hash = permitted_params.permit(:character_id, :icon_id, :character_alias_id)
      @empty_written = @post.build_new_reply_for(current_user, empty_reply_hash)
      @empty_written.editor_mode ||= params[:editor_mode] || current_user.default_editor
      @reply = @empty_written # So that editor_setup shows the correct characters
      @audits = {}
    end

    if multi_reply_to_add
      # Adding a new reply to the multi replies
      multi_reply_to_add.user = current_user unless multi_reply_to_add.user
      @multi_replies << multi_reply_to_add

      multi_reply_params[:id] = multi_reply_to_add.id if multi_reply_to_add.id.present?
      @multi_replies_json << multi_reply_params
    end

    @page_title = @post.subject

    editor_setup
    render :preview
  end

  def post_replies(new_reply: nil)
    @multi_replies << new_reply if new_reply.present?

    if @multi_replies_json.present? && (@reply = Reply.find_by_id(@multi_replies_json.first["id"]))
      # The first reply of the multi replies has an ID, that means I'm editing rather than posting a new one
      original_reply_params = permitted_params(ActionController::Parameters.new({ reply: @reply.attributes }))
      @reply.assign_attributes(permitted_params(ActionController::Parameters.new({ reply: @multi_replies_json.shift })))
      @multi_replies.shift
      edit_reply(original_reply_params: original_reply_params)
      return
    end

    first_reply = @multi_replies.first
    begin
      Reply.transaction { @multi_replies.each(&:save!) }
    rescue ActiveRecord::RecordInvalid => e
      errored_reply = @multi_replies.detect { |r| r.errors.present? } || first_reply
      render_errors(errored_reply, action: 'created', now: true, err: e)

      redirect_to posts_path and return unless errored_reply.post
      redirect_to post_path(errored_reply.post)
      return
    end

    if @multi_replies.length == 1
      flash[:success] = "Reply posted."
    else
      flash[:success] = "Replies posted."
    end
    redirect_to reply_path(first_reply, anchor: "reply-#{first_reply.id}")
  end

  def edit_reply(original_reply_params: nil)
    begin
      Reply.transaction do
        if @multi_replies.present?
          # Add new replies after the current one and before the next

          # Reorder the replies after this one
          original_reply_order = @reply.order
          num_new_replies = @multi_replies.length
          following_replies = @reply.post.replies.where("reply_order > ?", original_reply_order)
          following_replies.update_all(Arel.sql("reply_order = reply_order + ?", num_new_replies)) # rubocop:disable Rails/SkipsModelValidations

          # Create the new replies
          @multi_replies.each_with_index do |r, idx|
            # Create a fake temporary reply with the contents of the original one to be in history
            new_reply_params = permitted_params(ActionController::Parameters.new({ reply: r.attributes }))

            r.assign_attributes(original_reply_params)
            r.user = current_user
            r.created_at = @reply.created_at
            r.order = original_reply_order + idx + 1
            r.save!

            r.update!(new_reply_params)
          end
        end

        @reply.save!
      end
    rescue ActiveRecord::RecordInvalid => e
      if @multi_replies.blank?
        render_errors(@reply, action: 'updated', now: true, err: e)
      else
        errored_reply = @multi_replies.detect { |r| r.errors.present? } || @reply
        render_errors(errored_reply, action: 'updated', now: true, err: e)
      end

      @audits = { @reply.id => @post.audits.count }
      editor_setup
      render :edit
    else
      flash[:success] = "Reply updated."
      redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
    end
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
