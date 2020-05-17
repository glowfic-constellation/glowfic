class Reply::Drafter < Reply::Service
  attr_reader :draft

  def initialize(params, user:)
    super(nil, params: params, user: user)
  end

  def perform
    if (@draft = ReplyDraft.draft_for(@params[:reply][:post_id], @user.id))
      @draft.assign_attributes(permitted_params)
    else
      @draft = ReplyDraft.new(permitted_params)
      @draft.user = @user
    end
    @draft.save
  end
end
