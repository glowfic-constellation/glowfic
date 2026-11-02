# frozen_string_literal: true
class Api::V1::RepliesController < Api::ApiController
  before_action :login_required, only: :create

  resource_description do
    description 'Viewing and creating replies'
  end

  api :GET, '/posts/:id/replies', 'Load all the replies for a given post as JSON resources'
  param :post_id, :number, required: true, desc: "Post ID"
  param :page, :number, required: false, desc: 'Page in results'
  param :per_page, :number, required: false, desc: 'Number of replies to load per page. Defaults to 25, accepts values from 1-100 inclusive.'
  error 403, "Post is not visible to the user"
  error 404, "Post not found"
  def index
    return unless (post = find_object(Post, param: :post_id))
    access_denied and return unless post.visible_to?(current_user)

    replies = post.replies
      .select('replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username, users.deleted as user_deleted, character_aliases.name as alias')
      .joins(:user)
      .left_outer_joins(:character)
      .left_outer_joins(:icon)
      .left_outer_joins(:character_alias)
      .ordered
    paginate json: replies, per_page: per_page
  end

  api :POST, '/posts/:id/replies', 'Create a reply on a post as the current user. Applies the same rules as the reply form on the site.'
  header 'Authorization', 'Authorization token for a user in the format "Authorization" : "Bearer [token]"', required: true
  param :post_id, :number, required: true, desc: "Post ID"
  param :content, String, required: false, allow_blank: true, desc: "Reply content, written in the given editor mode"
  param :character_id, :number, required: false, allow_blank: true, desc: "ID of one of the user's characters. If not provided, the reply has no character."
  param :icon_id, :number, required: false, allow_blank: true, desc: "ID of one of the user's icons. If not provided, the reply has no icon."
  param :character_alias_id, :number, required: false, allow_blank: true, desc: "ID of an alias of the given character"
  param :editor_mode, Writable::EDITOR_MODES, required: false, allow_blank: true,
    desc: "How the content is written: 'html', 'rtf' or 'md'. Defaults to the user's default editor."
  param :last_seen_reply_id, :number, required: false, allow_blank: true,
    desc: "ID of the most recent reply in the post that the client has seen. If not provided, the user's read position on the site is used."
  param :allow_dupe, :boolean, required: false, desc: "If true, allows a reply that repeats the user's last reply in the post"
  error 401, "You must be logged in"
  error 403, "Post is not visible to the user, or the user cannot reply to it"
  error 404, "Post not found"
  error 409, "There are replies the user has not seen, or the reply looks like a duplicate"
  error 422, "Invalid parameters provided"
  def create
    return unless (post = find_object(Post, param: :post_id))
    access_denied and return unless can_reply_to?(post)

    reply = Reply.new(params.permit(:content, :character_id, :icon_id, :character_alias_id, :editor_mode))
    reply.post = post
    reply.user = current_user
    reply.editor_mode ||= Writable.editor_mode_or_nil(current_user.default_editor)

    errors = reply_errors(reply)
    render json: { errors: errors }, status: :unprocessable_content and return if errors.present?

    if params[:last_seen_reply_id].present?
      last_seen_reply = post.replies.find_by(id: params[:last_seen_reply_id])
      unless last_seen_reply
        error = { message: "Reply could not be found." }
        render json: { errors: [error] }, status: :unprocessable_content and return
      end
    else
      last_seen_reply = post.last_seen_reply_for(current_user)
    end

    # Same order as the site: the duplicate check comes before the unseen replies check
    unless ActiveModel::Type::Boolean.new.cast(params[:allow_dupe]) || reply.duplicated_reply.nil?
      message = "This looks like a duplicate. Did you attempt to post this twice? Resubmit with allow_dupe set to true if this was intentional."
      render json: { errors: [{ message: message }] }, status: :conflict and return
    end

    unseen_replies = post.unseen_replies_after(last_seen_reply)
    if unseen_replies.last.present?
      # Like the site, mark the replies in the response as read, so that a retry can succeed
      post.mark_read(current_user, at_time: post.read_time_for(unseen_replies))
      num = unseen_replies.count
      pluraled = num > 1 ? "have been #{num} new replies" : "has been 1 new reply"
      error = { message: "There #{pluraled} since you last viewed this post." }
      replies = unseen_replies.includes(:character, :icon, :user, :character_alias)
      render json: { errors: [error], unseen_replies: replies.as_json }, status: :conflict and return
    end

    begin
      reply.save!
    rescue ActiveRecord::RecordInvalid
      render json: { errors: messages_for(reply) }, status: :unprocessable_content and return
    end

    # The site shows the post after a reply is posted, which marks the new reply as read
    post.mark_read(current_user, at_time: post.read_time_for([reply]))
    render json: reply.as_json
  end

  api :GET, '/replies/:id/bookmark', "Load a user's bookmark attached to a reply if it exists and is visible"
  param :id, :number, required: true, desc: "Reply ID"
  param :user_id, :number, required: true, desc: "User ID"
  error 403, "Reply's post is not visible to the user"
  error 404, "Reply or user not found"
  error 422, "Invalid parameters provided"
  def bookmark
    return unless (reply = find_object(Reply))
    return unless (user = find_object(User, param: :user_id))
    access_denied and return unless reply.post.visible_to?(current_user)

    bookmark = reply.bookmarks.find_by(user_id: user.id, type: "reply_bookmark")
    bookmark_not_found and return unless bookmark&.visible_to?(current_user)

    render json: bookmark.as_json
  end

  private

  # The site only shows the reply form to users who can see the post and tag in it;
  # Reply validations then check board and post authorship again when the reply saves.
  def can_reply_to?(post)
    return false if current_user.deleted? || current_user.suspended?
    post.visible_to?(current_user) && post.taggable_by?(current_user)
  end

  def reply_errors(reply)
    errors = []
    errors << { message: "Character could not be found." } if reply.character_id.present? && reply.character.nil?
    errors << { message: "Icon could not be found." } if reply.icon_id.present? && reply.icon.nil?
    if reply.character_alias_id.present?
      if reply.character_alias.nil?
        errors << { message: "Character alias could not be found." }
      elsif reply.character_alias.character_id != reply.character_id
        errors << { message: "Character alias must belong to the reply's character." }
      end
    end
    errors + (reply.valid? ? [] : messages_for(reply))
  end

  def messages_for(reply)
    reply.errors.full_messages.map { |msg| { message: msg } }
  end

  def bookmark_not_found
    error = { message: "Bookmark could not be found." }
    render json: { errors: [error] }, status: :not_found
  end
end
