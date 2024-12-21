# frozen_string_literal: true
class Api::V1::RepliesController < Api::ApiController
  resource_description do
    description 'Viewing replies'
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

  api :GET, '/replies/:id/bookmark', "Load a user's bookmark attached to a reply if it exists and is visible"
  param :id, :number, required: true, desc: "Reply ID"
  param :user_id, :number, required: true, desc: "User ID"
  error 403, "Reply's post or user's bookmarks are not visible"
  error 404, "Reply or user not found"
  error 422, "Invalid parameters provided"
  def bookmark
    return unless (reply = find_object(Reply))
    return unless (user = find_object(User, param: :user_id))
    access_denied and return unless reply.post.visible_to?(current_user)

    if !user.public_bookmarks && user.id != current_user.try(:id)
      error = { message: "This user's bookmarks are private." }
      render json: { errors: [error] }, status: :forbidden
      return
    end

    bookmark = reply.bookmarks.find_by(user_id: user.id, type: "reply_bookmark")

    if bookmark.present?
      render json: bookmark.as_json
    else
      render json: {}
    end
  end
end
