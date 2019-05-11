class Reply::Drafter < Object
  attr_reader :draft

  def initialize(params, user:)
    @params = params
    if (@draft = ReplyDraft.draft_for(params[:reply][:post_id], current_user.id))
      @draft.assign_attributes(permitted_params)
    else
      @draft = ReplyDraft.new(permitted_params)
      @draft.user = user
    end
  end

  def save!
    @draft.save!
  end
end
