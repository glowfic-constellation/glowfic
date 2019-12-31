class UserPresenter
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def as_json(options={})
    return {} unless user
    return {id: user.id, username: '(deleted user)'} if user.deleted?
    return detailed_json(options) if options[:detailed]
    summary_json(options)
  end

  private

  def detailed_json(options={})
    attrs = %w(id username moiety moiety_name created_at)
    attr_json(attrs, options)
  end

  def summary_json(options={})
    attrs = %w(id username)
    attr_json(attrs, options)
  end

  def attr_json(attrs, options)
    user.as_json_without_presenter({only: attrs}.reverse_merge(options))
  end
end
