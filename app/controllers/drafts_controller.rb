# frozen_string_literal: true
class DraftsController < WritableController
  before_action :login_required
  before_action :readonly_forbidden, only: :create
  before_action :require_post_access, only: :create

  def create
    draft = make_draft
    redirect_to posts_path and return unless draft.post
    redirect_to post_path(draft.post, page: :unread, anchor: :unread)
  end

  def destroy
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
    redirect_to post_path(post_id, page: :unread, anchor: :unread)
  end

  private

  # a missing post is reported by the draft's own validation
  def require_post_access
    reply_post = Post.find_by(id: permitted_params[:post_id])
    return if reply_post.nil? || reply_post.visible_to?(current_user)
    flash[:error] = "You do not have permission to view this post."
    redirect_to continuities_path
  end
end
