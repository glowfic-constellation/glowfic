class ReplyPresenter
  attr_reader :reply

  def initialize(reply)
    @reply = reply
  end

  def as_json(options={})
    return {} unless reply
    { id: reply.id,
      content: reply.content,
      created_at: reply.created_at,
      updated_at: reply.updated_at,
      character: reply.character,
      icon: reply.icon,
      user: reply.user }
  end
end
