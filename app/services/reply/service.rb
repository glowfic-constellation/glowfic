class Reply::Service < Generic::Saver
  def initialize(model, user:, params:)
    @reply = model
    super
  end

  def permitted_params
    @params.fetch(:reply, {}).permit(
      :post_id,
      :content,
      :character_id,
      :icon_id,
      :audit_comment,
      :character_alias_id,
    )
  end
end
