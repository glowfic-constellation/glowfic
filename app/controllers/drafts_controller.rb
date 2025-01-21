# frozen_string_literal: true
class DraftsController < WritableController
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
end
