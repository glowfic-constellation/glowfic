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
      character: character(reply),
      icon: icon(reply),
      user: user(reply) }
  end

  def character(reply)
    return unless reply.character_id
    { id: reply.character_id,
      name: reply.name,
      screenname: reply.screenname }
  end

  def icon(reply)
    return unless reply.icon_id
    { id: reply.icon_id,
      url: reply.url,
      keyword: reply.keyword }
  end

  def user(reply)
    { id: reply.user_id,
      username: reply.username }
  end
end
