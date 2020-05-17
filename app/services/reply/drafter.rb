class Reply::Drafter < Reply::Service
  def initialize(params, user:)
    super(nil, params: params, user: user)
  end

  def perform
    if (draft = ReplyDraft.draft_for(params[:reply][:post_id], current_user.id))
      draft.assign_attributes(permitted_params)
    else
      draft = ReplyDraft.new(permitted_params)
      draft.user = current_user
    end
    draft.save
  end
end
