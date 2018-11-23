# frozen_string_literal: true
require 'will_paginate/array'

class RepliesController < WritableController
  before_action :login_required, except: [:search, :show, :history]
  before_action :find_reply, only: [:show, :history, :edit, :update, :destroy]
  before_action :editor_setup, only: [:edit]
  before_action :require_permission, only: [:edit, :update]

  def search
    @page_title = 'Search Replies'
    use_javascript('posts/search')

    @post = Post.find_by_id(params[:post_id]) if params[:post_id].present?
    @icon = Icon.find_by_id(params[:icon_id]) if params[:icon_id].present?
    if @post.try(:visible_to?, current_user)
      @users = @post.authors
      char_ids = @post.replies.select(:character_id).distinct.pluck(:character_id) + [@post.character_id]
      @characters = Character.where(id: char_ids).ordered
      @templates = Template.where(id: @characters.map(&:template_id).uniq.compact).ordered
      gon.post_id = @post.id
    else
      @users = User.where(id: params[:author_id]) if params[:author_id].present?
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
      .select('replies.*, characters.name, characters.screenname, users.username')
      .joins(:user)
      .left_outer_joins(:character)
      .with_edit_audit_counts
      .paginate(page: page, per_page: 25)
      .includes(:post)

    unless params[:condensed]
      @search_results = @search_results
        .select('icons.keyword, icons.url')
        .left_outer_joins(:icon)
    end

    if @search_results.total_pages <= 1
      @search_results = @search_results.select {|reply| reply.post.visible_to?(current_user)}.paginate(page: page, per_page: 25)
    end
  end

  def create
    if params[:button_draft]
      draft = make_draft
      redirect_to posts_path and return unless draft.post
      redirect_to post_path(draft.post, page: :unread, anchor: :unread) and return
    elsif params[:button_preview]
      draft = make_draft
      preview(ReplyDraft.reply_from_draft(draft)) and return
    end

    reply = Reply.new(reply_params)
    reply.user = current_user

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

      if reply.user_id.present? && !params[:allow_dupe].present?
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
    @reply.assign_attributes(reply_params)
    preview(@reply) and return if params[:button_preview]

    if current_user.id != @reply.user_id && @reply.audit_comment.blank?
      flash[:error] = "You must provide a reason for your moderator edit."
      editor_setup
      render action: :edit and return
    end

    @reply.audit_comment = nil if @reply.changes.empty? # don't save an audit for a note and no changes
    unless @reply.save
      flash[:error] = {}
      flash[:error][:message] = "Your reply could not be saved because of the following problems:"
      flash[:error][:array] = @reply.errors.full_messages
      editor_setup
      render action: :edit and return
    end

    flash[:success] = "Post updated"
    redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
  end

  def destroy
    unless @reply.deletable_by?(current_user)
      flash[:error] = "You do not have permission to modify this post."
      redirect_to post_path(@reply.post) and return
    end

    previous_reply = @reply.send(:previous_reply)
    to_page = previous_reply.try(:post_page, per_page) || 1

    # to destroy subsequent replies, do @reply.destroy_subsequent_replies
    begin
      @reply.destroy!
      flash[:success] = "Reply deleted."
      redirect_to post_path(@reply.post, page: to_page)
    rescue ActiveRecord::RecordNotDestroyed
      flash[:error] = {}
      flash[:error][:message] = "Reply could not be deleted."
      flash[:error][:array] = @reply.errors.full_messages
      redirect_to reply_path(@reply, anchor: "reply-#{@reply.id}")
    end
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
    @written = written
    @post = @written.post
    @written.user = current_user unless @written.user

    @page_title = @post.subject

    editor_setup
    render action: :preview
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

  def make_draft(show_message=true)
    if (draft = ReplyDraft.draft_for(params[:reply][:post_id], current_user.id))
      draft.assign_attributes(reply_params)
    else
      draft = ReplyDraft.new(reply_params)
      draft.user = current_user
    end

    if draft.save
      flash[:success] = "Draft saved!" if show_message
    else
      flash[:error] = {}
      flash[:error][:message] = "Your draft could not be saved because of the following problems:"
      flash[:error][:array] = draft.errors.full_messages
    end
    draft
  end
end
