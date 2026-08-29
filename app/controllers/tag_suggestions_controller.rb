# frozen_string_literal: true
class TagSuggestionsController < ApplicationController
  before_action :login_required
  before_action :readonly_forbidden
  before_action :find_post, only: [:new, :create]
  before_action :require_open_post, only: [:new]
  before_action :find_suggestion, only: [:accept, :reject, :allow_again]
  before_action :require_author, only: [:accept, :reject, :allow_again]

  def index
    @page_title = "Suggested Tags"
    @suggestions = TagSuggestion.where(post_id: current_user.posts.select(:id)).includes(:post, :user, :tag).ordered
    @pending = @suggestions.select(&:pending?)
    @endorsements = @suggestions.select(&:endorsed?)
    @resolved = @suggestions.select { |suggestion| suggestion.accepted? || suggestion.rejected? }
  end

  def new
    @page_title = "Suggest a Tag"
    @suggestion = TagSuggestion.new(post: @post)
  end

  def create
    tag = Tag.find_by(id: params.dig(:tag_suggestion, :tag_id))
    record, outcome = TagSuggestion.submit(
      post: @post,
      user: current_user,
      tag: tag,
      tag_type: tag ? nil : params.dig(:tag_suggestion, :tag_type).presence,
      tag_name: tag ? nil : params.dig(:tag_suggestion, :tag_name).presence,
      note: params.dig(:tag_suggestion, :note).presence,
      spoiler: params.dig(:tag_suggestion, :spoiler) == '1',
      reveal_after_reply_order: params.dig(:tag_suggestion, :reveal_after_reply_order).presence,
    )

    case outcome
      when :already_visible
        flash[:error] = "Tag is already applied to this post."
        redirect_to post_path(@post)
      when :not_accepted
        flash[:error] = "This post does not accept tag suggestions."
        redirect_to post_path(@post)
      when :invalid
        @suggestion = record
        flash.now[:error] = { message: "Suggestion could not be saved", array: record.errors.full_messages }
        @page_title = "Suggest a Tag"
        render :new
      else
        # :created, :endorsed and :silently_deduped are indistinguishable to the
        # suggester on purpose; see TagSuggestion.submit.
        flash[:success] = "Suggestion recorded. The post author will review it."
        redirect_to post_path(@post)
    end
  end

  def accept
    @suggestion.accept!(resolver: current_user)
    flash[:success] = "Tag #{@suggestion.tag_display_name} applied."
    redirect_to tag_suggestions_path
  end

  def reject
    @suggestion.reject!(resolver: current_user)
    flash[:success] = "Tag #{@suggestion.tag_display_name} declined. It cannot be suggested on this post again."
    redirect_to tag_suggestions_path
  end

  def allow_again
    name = @suggestion.tag_display_name
    @suggestion.allow_again!
    flash[:success] = "Tag #{name} may be suggested again."
    redirect_to tag_suggestions_path
  end

  private

  def find_post
    @post = Post.find_by(id: params[:post_id])
    return if @post&.visible_to?(current_user)
    flash[:error] = "Post could not be found."
    redirect_to posts_path
  end

  def require_open_post
    return if @post.allow_tag_suggestions?
    flash[:error] = "This post does not accept tag suggestions."
    redirect_to post_path(@post)
  end

  def find_suggestion
    @suggestion = TagSuggestion.find_by(id: params[:id])
    return if @suggestion
    flash[:error] = "Suggestion could not be found."
    redirect_to tag_suggestions_path
  end

  def require_author
    return if @suggestion.post.user_id == current_user.id
    flash[:error] = "You do not have permission to resolve this suggestion."
    redirect_to tag_suggestions_path
  end
end
