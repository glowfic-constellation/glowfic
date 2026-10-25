# frozen_string_literal: true
class ReplyPresenter
  attr_reader :reply

  def initialize(reply)
    @reply = reply
  end

  def as_json(options={})
    reply_json = {
      id: reply.id,
      content: reply.content,
      created_at: reply.created_at,
      updated_at: reply.updated_at,
      character_name: reply.name, # handles alias
      character: character(reply),
      icon: icon(reply),
      user: user(reply),
    }
    includes = (options || {})[:include] || []
    reply_json[:post] = post(reply) if includes.include?(:post)
    # the matching excerpts from a content search, as the HTML reply search shows them
    reply_json[:highlight] = Glowfic::Sanitizers.written(reply.pg_search_highlight) if includes.include?(:highlight)
    reply_json
  end

  def character(reply)
    return unless reply.character_id
    {
      id: reply.character_id,
      name: reply.character_name, # explicitly does not include alias
      screenname: reply.screenname,
    }
  end

  def icon(reply)
    return unless reply.icon_id
    {
      id: reply.icon_id,
      url: reply.url,
      keyword: reply.keyword,
    }
  end

  def post(reply)
    {
      id: reply.post_id,
      subject: reply.post.subject,
    }
  end

  def user(reply)
    {
      id: reply.user_id,
      username: reply.username,
    }
  end
end
