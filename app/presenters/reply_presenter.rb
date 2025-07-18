# frozen_string_literal: true
class ReplyPresenter
  attr_reader :reply

  def initialize(reply)
    @reply = reply
  end

  def as_json(_options={})
    dict = {
      id: reply.id,
      content: reply.content,
      created_at: reply.created_at,
      updated_at: reply.updated_at,
      character_name: reply.name, # handles alias
      character: character(reply),
      icon: icon(reply),
      user: user(reply),
    }
    return dict unless @reply.user_id == _options[:user]&.id
    dict.merge(editor_mode: @reply.editor_mode)
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

  def user(reply)
    {
      id: reply.user_id,
      username: reply.username,
    }
  end
end
